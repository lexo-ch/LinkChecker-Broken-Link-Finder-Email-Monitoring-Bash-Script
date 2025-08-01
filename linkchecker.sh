#!/bin/bash

#==============================================================================
# Website Linkchecker Script
#
# This script runs linkchecker on a website and sends an HTML email report
# if any broken links are found. Additionally checks YouTube video availability.
#
# CRON Behavior:
# - Silent operation: Only errors appear on stderr (triggering CRON emails)
# - All INFO/DEBUG messages go only to log file when DEBUG=false
# - Set DEBUG=true for verbose console output
# - Script exits with error if log file is not writable
#
# Known issues
# 2025-07-28	Current version of linkchecker (10.5.0, release 2024-09-03) encounters issues if the link protocol is not written in all small caps.
#		In tests it sometimes does not process HTTPS whereas it processes the same link without issues if the protocol is written in small caps (https)
#
# Author: LEXO
# Date: 2025-07-28
#==============================================================================

# Configuration
SCRIPT_NAME="LEXO Linkchecker"
SCRIPT_VERSION="1.6"
USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.48 Safari/537.36"
LOGO_URL="https://www.lexo.ch/brandings/lexo-logo-signature.png"
LOG_FILE="${LOG_FILE:-/var/log/linkchecker.log}"
DEBUG="${DEBUG:-false}"

# Linkchecker binary path
LINKCHECKER_BINARY="/usr/local/bin/linkchecker"

# Linkchecker parameters - easily configurable
LINKCHECKER_PARAMS="--recursion-level=-1 --timeout=30 --threads=30"

# Email configuration
MAIL_SENDER="websupport@lexo.ch"
MAIL_SENDER_NAME="LEXO | Web Support"

# YouTube domains REGEX - will match on all *.youtube.[country], *.youtube.co.* as well as various short URLs like yt.be or youtu.be
YOUTUBE_DOMAINS='https?:\/\/(([a-z0-9-]+\.)*)?(youtube(-nocookie)?\.([a-z]{2,3})(\.[a-z]{2})?|youtu\.be|yt\.be)($|\/|\?)'

# YouTube oEmbed rate limiting
YOUTUBE_OEMBED_DELAY=1  # Delay in seconds between requests
YOUTUBE_OEMBED_MAX_PER_MINUTE=30  # Max requests per minute (conservative)
YOUTUBE_OEMBED_TIMEOUT=10  # Timeout for each request

# Global exclude patterns (REGEX) - one pattern per line
EXCLUDES=(
    "\/xmlrpc\.php\b"
#   "\?p=[0-9]+"
)

# Initialize arrays
declare -a ERROR_URL_LIST=()
declare -a ERROR_TEXT_LIST=()
declare -a ERROR_PARENT_LIST=()
declare -a DYNAMIC_EXCLUDES=()
declare -a TEMP_FILES=()
declare -a REMAINING_ARGS=()
declare -a ALL_URLS_LIST=()
declare -a ALL_URLS_PARENT=()
declare -a YOUTUBE_ERROR_URLS=()
declare -a YOUTUBE_ERROR_TEXT=()
declare -a YOUTUBE_ERROR_PARENT=()

# Global counters
TOTAL_URLS=0
ERROR_URLS=0
EXCLUDED_URLS=0
CHECK_DURATION=0
ERRORS_FOUND=false
YOUTUBE_URLS_CHECKED=0
YOUTUBE_ERRORS=0

# Language variables - will be set by set_language_texts()
LANG_SUBJECT=""
LANG_INTRO_TITLE=""
LANG_INTRO_TEXT=""
LANG_CMS_TITLE=""
LANG_CMS_TEXT=""
LANG_SUMMARY_TITLE=""
LANG_DETAILS_TITLE=""
LANG_DURATION=""
LANG_TOTAL_URLS=""
LANG_ERROR_URLS=""
LANG_SUCCESS_RATE=""
LANG_COLUMN_URL=""
LANG_COLUMN_ERROR=""
LANG_COLUMN_PARENT=""
LANG_FOOTER_TEXT=""
LANG_TIMEOUT_ERROR=""
LANG_YOUTUBE_SECTION=""
LANG_YOUTUBE_URLS_CHECKED=""
LANG_YOUTUBE_ERRORS=""
LANG_YOUTUBE_VIDEO_DELETED=""
LANG_YOUTUBE_VIDEO_PRIVATE=""
LANG_YOUTUBE_CHECK_FAILED=""

#==============================================================================
# Helper Functions (must be defined first)
#==============================================================================

# Error handling
die() {
    echo "ERROR: $1" >&2
    exit 1
}

# Cleanup on exit
cleanup() {
    local exit_code=$?
    for temp_file in "${TEMP_FILES[@]}"; do
        [[ -f "$temp_file" ]] && rm -f "$temp_file" 2>/dev/null || true
    done
    return $exit_code
}
trap cleanup EXIT

# Logging functions
log_message() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local message="[$timestamp] INFO: $1"
    echo "$message" >> "$LOG_FILE" 2>/dev/null || true
    # Only output to console if DEBUG is true
    if [[ "$DEBUG" == "true" ]]; then
        echo "$message"
    fi
}

debug_message() {
    if [[ "$DEBUG" == "true" ]]; then
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        local message="[$timestamp] DEBUG: $1"
        echo "$message" >> "$LOG_FILE" 2>/dev/null || true
        echo "$message"
    fi
}

error_message() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local message="[$timestamp] ERROR: $1"
    echo "$message" >> "$LOG_FILE" 2>/dev/null || true
    # Always output errors to stderr (for CRON to catch)
    echo "$message" >&2
}

# Add temp file for cleanup
add_temp_file() {
    [[ -n "${1:-}" ]] && TEMP_FILES+=("$1")
}

# Safe field cleaning function that handles quotes properly
clean_field() {
    local field="$1"
    # Remove leading/trailing whitespace without using xargs
    field="${field#"${field%%[![:space:]]*}"}"  # Remove leading whitespace
    field="${field%"${field##*[![:space:]]}"}"  # Remove trailing whitespace
    echo "$field"
}

#==============================================================================
# YouTube Functions
#==============================================================================

# Check if URL is a YouTube URL
is_youtube_url() {
    local url="$1"
    # Convert URL to lowercase first
    local url_lower="${url,,}"
    # Use grep with PCRE support (-P) on the lowercase URL
    if echo "$url_lower" | grep -Pqi "${YOUTUBE_DOMAINS}"; then
        return 0
    fi
    return 1
}

# Extract YouTube video ID from various URL formats
extract_youtube_video_id() {
    local url="$1"
    local video_id=""

    # Handle youtu.be short URLs
    if [[ "$url" =~ youtu\.be/([a-zA-Z0-9_-]+) ]]; then
        video_id="${BASH_REMATCH[1]}"
    # Handle youtube.com/watch?v= URLs (with ? or &)
    elif [[ "$url" =~ \?v=([a-zA-Z0-9_-]+) ]] || [[ "$url" =~ \&v=([a-zA-Z0-9_-]+) ]]; then
        video_id="${BASH_REMATCH[1]}"
    # Handle youtube.com/embed/ URLs
    elif [[ "$url" =~ /embed/([a-zA-Z0-9_-]+) ]]; then
        video_id="${BASH_REMATCH[1]}"
    # Handle youtube.com/v/ URLs
    elif [[ "$url" =~ /v/([a-zA-Z0-9_-]+) ]]; then
        video_id="${BASH_REMATCH[1]}"
    fi

    # Clean up video ID - remove any trailing & or # parameters
    video_id="${video_id%%&*}"
    video_id="${video_id%%#*}"

    echo "$video_id"
}

# Check YouTube video availability using oEmbed
check_youtube_video() {
    local video_id="$1"
    local status
    local response

    # Build oEmbed URL
    local oembed_url="https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=${video_id}&format=json"

    debug_message "Checking YouTube video: $video_id"

    # Make oEmbed request with timeout
    response=$(curl -s -w "\n%{http_code}" --max-time "$YOUTUBE_OEMBED_TIMEOUT" "$oembed_url" 2>/dev/null)
    status=$(echo "$response" | tail -n1)

    # Return status code
    echo "$status"
}

# Process YouTube URLs found by linkchecker
process_youtube_urls() {
    local youtube_count=0
    local requests_this_minute=0
    local minute_start=$(date +%s)

    log_message "Starting YouTube video availability check"

    # Reset YouTube error arrays
    YOUTUBE_ERROR_URLS=()
    YOUTUBE_ERROR_TEXT=()
    YOUTUBE_ERROR_PARENT=()
    YOUTUBE_URLS_CHECKED=0
    YOUTUBE_ERRORS=0

    # Process each URL found by linkchecker
    for i in "${!ALL_URLS_LIST[@]}"; do
        local url="${ALL_URLS_LIST[$i]}"
        local parent="${ALL_URLS_PARENT[$i]}"

        # Check if it's a YouTube URL
        if ! is_youtube_url "$url"; then
            continue
        fi

        ((youtube_count++))

        # Extract video ID
        local video_id=$(extract_youtube_video_id "$url")
        if [[ -z "$video_id" ]]; then
            debug_message "Could not extract video ID from: $url"
            continue
        fi

        # Rate limiting check
        local current_time=$(date +%s)
        if (( current_time - minute_start >= 60 )); then
            # Reset minute counter
            minute_start=$current_time
            requests_this_minute=0
        fi

        if (( requests_this_minute >= YOUTUBE_OEMBED_MAX_PER_MINUTE )); then
            # Wait until next minute
            local wait_time=$((60 - (current_time - minute_start)))
            debug_message "Rate limit reached, waiting ${wait_time}s"
            sleep "$wait_time"
            minute_start=$(date +%s)
            requests_this_minute=0
        fi

        # Check video availability
        local status=$(check_youtube_video "$video_id")
        ((requests_this_minute++))
        ((YOUTUBE_URLS_CHECKED++))

        # Process result
        if [[ "$status" == "200" ]]; then
            debug_message "YouTube video OK: $video_id"
        elif [[ -n "$status" ]]; then
            # Any non-200 status is an error
            YOUTUBE_ERROR_URLS+=("$url")
            YOUTUBE_ERROR_TEXT+=("$LANG_YOUTUBE_VIDEO_DELETED (HTTP $status)")
            YOUTUBE_ERROR_PARENT+=("$parent")
            ((YOUTUBE_ERRORS++))
            log_message "YouTube video not found: $url (ID: $video_id, Status: $status)"
        else
            # Empty status means timeout or connection failure
            YOUTUBE_ERROR_URLS+=("$url")
            YOUTUBE_ERROR_TEXT+=("$LANG_YOUTUBE_CHECK_FAILED")
            YOUTUBE_ERROR_PARENT+=("$parent")
            ((YOUTUBE_ERRORS++))
            error_message "YouTube check timeout: $url"
        fi

        # Rate limiting delay
        if (( requests_this_minute < YOUTUBE_OEMBED_MAX_PER_MINUTE )); then
            sleep "$YOUTUBE_OEMBED_DELAY"
        fi
    done

    log_message "YouTube check complete: $YOUTUBE_URLS_CHECKED checked, $YOUTUBE_ERRORS errors found"

    # Update global error flag if YouTube errors found
    if (( YOUTUBE_ERRORS > 0 )); then
        ERRORS_FOUND=true
    fi
}

#==============================================================================
# Core Functions
#==============================================================================

# Check if URL should be excluded
is_url_excluded() {
    local url="$1"

    # Check all exclude patterns
    for pattern in "${EXCLUDES[@]}" "${DYNAMIC_EXCLUDES[@]}"; do
        if [[ "$url" =~ $pattern ]]; then
            debug_message "URL excluded by pattern '$pattern': $url"
            return 0
        fi
    done
    return 1
}

# Show usage
show_usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] <base_url> <cms_login_url> <language> <mailto>

Parameters:
  base_url        Base URL to check (e.g., https://www.example.com)
  cms_login_url   CMS login URL or "-" if none
  language        Report language: de or en
  mailto          Comma-separated email addresses

Options:
  --exclude=REGEX Add exclude pattern (can be used multiple times)
  --debug         Enable debug output
  -h, --help      Show this help

Environment:
  DEBUG=true      Enable debug output
  LOG_FILE=path   Set log file location (default: $LOG_FILE)

Features:
  - Checks all links on website using linkchecker
  - Additionally checks YouTube video availability using oEmbed API
  - Sends HTML email report if broken links or unavailable videos found
  - Rate limiting for YouTube API (max $YOUTUBE_OEMBED_MAX_PER_MINUTE requests/minute)

Examples:
  $(basename "$0") https://example.com - en admin@example.com
  $(basename "$0") --exclude='\.pdf$' https://example.com - de admin@example.com

CRON Usage:
  # Silent operation (only errors to stderr)
  0 2 * * * /path/to/linkchecker.sh https://example.com - en admin@example.com

  # With custom log file
  0 2 * * * LOG_FILE=/home/user/linkchecker.log /path/to/linkchecker.sh https://example.com - en admin@example.com
EOF
}

# Set language texts
set_language_texts() {
    local lang="$1"

    if [[ "$lang" == "en" ]]; then
        LANG_SUBJECT="Broken Links Found on Website"
        LANG_INTRO_TITLE="Broken Links Discovered on Your Website"
        LANG_INTRO_TEXT="The automatic check found broken links on your website"
        LANG_CMS_TITLE="CMS Login"
        LANG_CMS_TEXT="To fix these issues, you can log in at the following link:"
        LANG_SUMMARY_TITLE="Summary"
        LANG_DETAILS_TITLE="Detailed Error Report"
        LANG_DURATION="Check Duration"
        LANG_TOTAL_URLS="Total URLs Checked"
        LANG_ERROR_URLS="URLs with Errors"
        LANG_SUCCESS_RATE="Success Rate"
        LANG_COLUMN_URL="URL"
        LANG_COLUMN_ERROR="Error"
        LANG_COLUMN_PARENT="Found on Page"
        LANG_FOOTER_TEXT="This report was generated automatically by $SCRIPT_NAME."
        LANG_TIMEOUT_ERROR="Request timeout (>30s)"
        LANG_YOUTUBE_SECTION="YouTube Video Errors"
        LANG_YOUTUBE_URLS_CHECKED="YouTube URLs Checked"
        LANG_YOUTUBE_ERRORS="YouTube Videos Unavailable"
        LANG_YOUTUBE_VIDEO_DELETED="Video deleted or unavailable"
        LANG_YOUTUBE_VIDEO_PRIVATE="Video is private"
        LANG_YOUTUBE_CHECK_FAILED="Could not check video status"
    else
        LANG_SUBJECT="Defekte Links auf der Website gefunden"
        LANG_INTRO_TITLE="Fehlerhafte Links auf Ihrer Webseite entdeckt"
        LANG_INTRO_TEXT="Die automatische Überprüfung fand fehlerhafte Links auf Ihrer Webseite"
        LANG_CMS_TITLE="CMS Login"
        LANG_CMS_TEXT="Für das Beheben der Probleme können Sie sich unter folgendem Link einloggen:"
        LANG_SUMMARY_TITLE="Zusammenfassung"
        LANG_DETAILS_TITLE="Detaillierter Fehlerbericht"
        LANG_DURATION="Überprüfungsdauer"
        LANG_TOTAL_URLS="Anzahl überprüfter URLs"
        LANG_ERROR_URLS="URLs mit Fehlern"
        LANG_SUCCESS_RATE="Erfolgsrate"
        LANG_COLUMN_URL="URL"
        LANG_COLUMN_ERROR="Fehler"
        LANG_COLUMN_PARENT="Gefunden auf Seite"
        LANG_FOOTER_TEXT="Dieser Bericht wurde automatisch vom $SCRIPT_NAME generiert."
        LANG_TIMEOUT_ERROR="Anfrage-Zeitüberschreitung (>30s)"
        LANG_YOUTUBE_SECTION="YouTube Video Fehler"
        LANG_YOUTUBE_URLS_CHECKED="YouTube URLs überprüft"
        LANG_YOUTUBE_ERRORS="YouTube Videos nicht verfügbar"
        LANG_YOUTUBE_VIDEO_DELETED="Video gelöscht oder nicht verfügbar"
        LANG_YOUTUBE_VIDEO_PRIVATE="Video ist privat"
        LANG_YOUTUBE_CHECK_FAILED="Videostatus konnte nicht geprüft werden"
    fi
}

# Parse command line arguments
parse_arguments() {
    # Use global array REMAINING_ARGS
    REMAINING_ARGS=()

    while [[ $# -gt 0 ]]; do
        case $1 in
            --exclude=*)
                local pattern="${1#*=}"
                if [[ -z "$pattern" ]]; then
                    die "Empty exclude pattern"
                fi
                DYNAMIC_EXCLUDES+=("$pattern")
                debug_message "Added exclude pattern: $pattern"
                shift
                ;;
            --debug)
                DEBUG="true"
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            -*)
		if [[ "$1" == "-" ]]; then
			# Single dash is a valid parameter value, not an option
			REMAINING_ARGS+=("$1")
			shift
		else
			die "Unknown option: $1"
		fi
                ;;
            *)
                REMAINING_ARGS+=("$1")
                shift
                ;;
        esac
    done
}

# Validate parameters
validate_parameters() {
    local base_url="$1"
    local cms_login_url="$2"
    local language="$3"
    local mailto="$4"

    [[ "$base_url" =~ ^https?:// ]] || die "Invalid base URL: $base_url"
    [[ "$cms_login_url" == "-" || "$cms_login_url" =~ ^https?:// ]] || die "Invalid CMS URL: $cms_login_url"
    [[ "$language" =~ ^(de|en)$ ]] || die "Language must be 'de' or 'en'"
    [[ "$mailto" =~ @ ]] || die "Invalid email format: $mailto"
}

# Check prerequisites
check_prerequisites() {
    # Check linkchecker
    if [[ ! -x "$LINKCHECKER_BINARY" ]]; then
        die "linkchecker not found or not executable at: $LINKCHECKER_BINARY"
    fi

    # Check mail command
    if ! command -v mail &>/dev/null; then
        die "mail command not found"
    fi

    # Check curl command (for YouTube checks)
    if ! command -v curl &>/dev/null; then
        die "curl command not found"
    fi

    # Check log file writability - CRITICAL for CRON
    if ! touch "$LOG_FILE" 2>/dev/null; then
        # For CRON: Exit with error so CRON will notify
        die "Cannot write to log file: $LOG_FILE - Set LOG_FILE environment variable to a writable location"
    fi

    debug_message "Prerequisites OK"
}

# Parse linkchecker output
parse_linkchecker_output() {
    local file="$1"
    local in_csv=false

    debug_message "Parsing linkchecker output from: $file"

    # Reset counters and arrays
    TOTAL_URLS=0
    ERROR_URLS=0
    EXCLUDED_URLS=0
    ERRORS_FOUND=false
    ERROR_URL_LIST=()
    ERROR_TEXT_LIST=()
    ERROR_PARENT_LIST=()
    ALL_URLS_LIST=()
    ALL_URLS_PARENT=()

    while IFS= read -r line; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^# ]] && continue

        # Detect CSV section
        if [[ "$line" =~ ^urlname\; ]]; then
            in_csv=true
            debug_message "Found CSV header"
            continue
        fi

        # Process CSV data
        if [[ "$in_csv" == true && "$line" =~ ^https?:// ]]; then
            # Parse CSV line
            IFS=';' read -r url parent base result rest <<< "$line"

            # Clean fields safely without xargs
            url=$(clean_field "$url")
            parent=$(clean_field "$parent")
            result=$(clean_field "$result")

            debug_message "Checking URL: $url (result: $result)"

            # Store all URLs for YouTube checking
            ALL_URLS_LIST+=("$url")
            ALL_URLS_PARENT+=("$parent")

            # Check exclusion
            if is_url_excluded "$url"; then
                ((EXCLUDED_URLS++))
                continue
            fi

            ((TOTAL_URLS++))

            # Check for errors
            local error_text=""
            if [[ "$result" =~ ^[0-9]+$ ]] && [[ "$result" -ge 400 ]]; then
                error_text="HTTP $result"
            elif [[ "$result" =~ ^[0-9]+ ]]; then
                local code="${result%% *}"
                [[ "$code" -ge 400 ]] && error_text="$result"
            elif [[ "$result" =~ [Tt]imeout ]]; then
                error_text="${LANG_TIMEOUT_ERROR:-Request timeout}"
            elif [[ "$result" =~ [Ee]rror|[Ff]ailed ]]; then
                error_text="$result"
            fi

            if [[ -n "$error_text" ]]; then
                ERROR_URL_LIST+=("$url")
                ERROR_TEXT_LIST+=("$error_text")
                ERROR_PARENT_LIST+=("$parent")
                ((ERROR_URLS++))
                ERRORS_FOUND=true
                debug_message "Error found: $url -> $error_text"
            fi
        fi
    done < "$file"

    log_message "Linkchecker results: $TOTAL_URLS checked, $ERROR_URLS errors, $EXCLUDED_URLS excluded"
}

# Run linkchecker
run_linkchecker() {
    local base_url="$1"
    local temp_output="/tmp/linkchecker_$$_$(date +%s).txt"
    add_temp_file "$temp_output"

    log_message "Starting linkchecker on $base_url"
    debug_message "Output file: $temp_output"

    local start_time=$(date +%s)

    # Run linkchecker with configurable parameters
    debug_message "Executing: $LINKCHECKER_BINARY --user-agent=\"$USER_AGENT\" $LINKCHECKER_PARAMS --check-extern --output=csv \"$base_url\""

    "$LINKCHECKER_BINARY" \
        --user-agent="$USER_AGENT" \
        $LINKCHECKER_PARAMS \
        --check-extern \
        --output=csv \
        "$base_url" > "$temp_output" 2>&1 || {
        local exit_code=$?
        if [[ $exit_code -ne 1 ]]; then
            error_message "linkchecker failed with exit code $exit_code"
            error_message "Output:"
            cat "$temp_output" >&2
            return 1
        fi
    }

    CHECK_DURATION=$(($(date +%s) - start_time))
    debug_message "Linkchecker completed in ${CHECK_DURATION}s"

    # Parse output
    parse_linkchecker_output "$temp_output"
}

# Generate HTML report
generate_html_report() {
    local base_url="$1"
    local cms_login_url="$2"
    local language="$3"
    local output_file="$4"

    debug_message "Generating HTML report to: $output_file"

    # Calculate stats
    local success_rate=100
    if [[ $TOTAL_URLS -gt 0 ]]; then
        success_rate=$(( (TOTAL_URLS - ERROR_URLS) * 100 / TOTAL_URLS ))
    fi

    # Total errors including YouTube
    local total_errors=$((ERROR_URLS + YOUTUBE_ERRORS))

    # Format duration
    local duration="${CHECK_DURATION}s"
    [[ $CHECK_DURATION -ge 60 ]] && duration="$((CHECK_DURATION / 60))m $((CHECK_DURATION % 60))s"

    # Generate HTML
    cat > "$output_file" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
EOF

    echo "    <title>$LANG_SUBJECT</title>" >> "$output_file"

    cat >> "$output_file" << 'EOF'
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 10px; background: #f5f5f5; }
        .container { max-width: 100%; margin: 0 auto; background: white; padding: 20px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { text-align: center; margin-bottom: 30px; }
        .logo { max-width: 200px; height: auto; margin-bottom: 20px; }
        h1 { color: #2c3e50; font-size: 22px; }
        h2 { color: #34495e; margin-top: 30px; font-size: 16px; border-bottom: 2px solid #3498db; padding-bottom: 5px; }
        .intro { background: #ecf0f1; padding: 15px; border-radius: 5px; margin-bottom: 20px; }
        .intro a { color: #2980b9; text-decoration: none; }
        .cms-link { background: #e8f5e8; padding: 10px; border-radius: 5px; margin-bottom: 20px; }
        .cms-link a { color: #27ae60; text-decoration: none; font-weight: bold; }
        table { width: 100%; border-collapse: collapse; margin-bottom: 20px; }
        th, td { padding: 8px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background: #3498db; color: white; }
        .summary-table { background: #f8f9fa; }
        .summary-table th { background: #6c757d; width: 300px; }
        .error-table tr:nth-child(even) { background: #f2f2f2; }
        .url-cell { word-break: break-all; max-width: 40%; }
        .url-cell a { color: #2980b9; text-decoration: none; }
        .error-cell { color: #e74c3c; font-weight: bold; }
        .footer { text-align: center; margin-top: 30px; padding-top: 20px; border-top: 1px solid #ddd; font-size: 11px; color: #7f8c8d; }
        .success-rate { color: #27ae60; font-weight: bold; }
        .error-count { color: #e74c3c; font-weight: bold; }
        .youtube-section { margin-top: 40px; }
        .youtube-error { background: #fff3cd; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
EOF

    cat >> "$output_file" << EOF
            <img src="$LOGO_URL" alt="Logo" class="logo">
            <h1>$LANG_INTRO_TITLE</h1>
        </div>

        <div class="intro">
            <p>$LANG_INTRO_TEXT <a href="$base_url">$base_url</a>. 
EOF

    if [[ "$language" == "en" ]]; then
        echo "Please review this report and fix the issues.</p>" >> "$output_file"
    else
        echo "Bitte prüfen Sie den vorliegenden Bericht und beheben Sie die Probleme.</p>" >> "$output_file"
    fi

    echo "        </div>" >> "$output_file"

    # CMS link if provided
    if [[ "$cms_login_url" != "-" ]]; then
        cat >> "$output_file" << EOF
        <div class="cms-link">
            <h2>$LANG_CMS_TITLE</h2>
            <p style="margin: 0;">$LANG_CMS_TEXT <a href="$cms_login_url">$cms_login_url</a></p>
        </div>
EOF
    fi

    # Summary table
    cat >> "$output_file" << EOF
        <h2>$LANG_SUMMARY_TITLE</h2>
        <table class="summary-table">
            <tr><th>$LANG_DURATION</th><td>$duration</td></tr>
            <tr><th>$LANG_TOTAL_URLS</th><td>$TOTAL_URLS</td></tr>
            <tr><th>$LANG_ERROR_URLS</th><td class="error-count">$ERROR_URLS</td></tr>
EOF

    # Add YouTube stats if any were checked
    if (( YOUTUBE_URLS_CHECKED > 0 )); then
        cat >> "$output_file" << EOF
            <tr><th>$LANG_YOUTUBE_URLS_CHECKED</th><td>$YOUTUBE_URLS_CHECKED</td></tr>
            <tr><th>$LANG_YOUTUBE_ERRORS</th><td class="error-count">$YOUTUBE_ERRORS</td></tr>
EOF
    fi

    cat >> "$output_file" << EOF
            <tr><th>$LANG_SUCCESS_RATE</th><td class="success-rate">${success_rate}%</td></tr>
        </table>
EOF

    # Regular link errors
    if (( ERROR_URLS > 0 )); then
        cat >> "$output_file" << EOF
        <h2>$LANG_DETAILS_TITLE</h2>
        <table class="error-table">
            <thead>
                <tr>
                    <th>$LANG_COLUMN_URL</th>
                    <th>$LANG_COLUMN_ERROR</th>
                    <th>$LANG_COLUMN_PARENT</th>
                </tr>
            </thead>
            <tbody>
EOF

        # Add error rows
        for i in "${!ERROR_URL_LIST[@]}"; do
            local url="${ERROR_URL_LIST[$i]//&/&amp;}"
            local error="${ERROR_TEXT_LIST[$i]//&/&amp;}"
            local parent="${ERROR_PARENT_LIST[$i]//&/&amp;}"

            cat >> "$output_file" << EOF
                <tr>
                    <td class="url-cell"><a href="${url//\"/&quot;}">$url</a></td>
                    <td class="error-cell">$error</td>
                    <td class="url-cell"><a href="${parent//\"/&quot;}">$parent</a></td>
                </tr>
EOF
        done

        echo "            </tbody>" >> "$output_file"
        echo "        </table>" >> "$output_file"
    fi

    # YouTube errors section
    if (( YOUTUBE_ERRORS > 0 )); then
        cat >> "$output_file" << EOF
        <div class="youtube-section">
            <h2>$LANG_YOUTUBE_SECTION</h2>
            <table class="error-table">
                <thead>
                    <tr>
                        <th>$LANG_COLUMN_URL</th>
                        <th>$LANG_COLUMN_ERROR</th>
                        <th>$LANG_COLUMN_PARENT</th>
                    </tr>
                </thead>
                <tbody>
EOF

        # Add YouTube error rows
        for i in "${!YOUTUBE_ERROR_URLS[@]}"; do
            local url="${YOUTUBE_ERROR_URLS[$i]//&/&amp;}"
            local error="${YOUTUBE_ERROR_TEXT[$i]//&/&amp;}"
            local parent="${YOUTUBE_ERROR_PARENT[$i]//&/&amp;}"

            cat >> "$output_file" << EOF
                <tr class="youtube-error">
                    <td class="url-cell"><a href="${url//\"/&quot;}">$url</a></td>
                    <td class="error-cell">$error</td>
                    <td class="url-cell"><a href="${parent//\"/&quot;}">$parent</a></td>
                </tr>
EOF
        done

        echo "                </tbody>" >> "$output_file"
        echo "            </table>" >> "$output_file"
        echo "        </div>" >> "$output_file"
    fi

    # Footer
    cat >> "$output_file" << EOF
        <div class="footer">
            <p>$LANG_FOOTER_TEXT</p>
            <p>$(date '+%d.%m.%Y, %H:%M:%S')</p>
        </div>
    </div>
</body>
</html>
EOF
}

# Send email
send_email() {
    local mailto="$1"
    local base_url="$2"
    local html_file="$3"
    local domain="${base_url#*://}"
    domain="${domain%%/*}"
    local subject="$LANG_SUBJECT - $domain"

    log_message "Sending email to: $mailto"

    if (
        echo "To: $mailto"
        echo "From: $MAIL_SENDER_NAME <$MAIL_SENDER>"
        echo "Reply-To: $MAIL_SENDER"
        echo "Subject: $subject"
        echo "Content-Type: text/html; charset=UTF-8"
        echo ""
        cat "$html_file"
    ) | sendmail -f "$MAIL_SENDER" "$mailto" 2>&1; then
        log_message "Email sent successfully"
        return 0
    else
        error_message "Failed to send email"
        return 1
    fi
}

#==============================================================================
# Main function
#==============================================================================
main() {
    debug_message "Script starting..."

    # Detect if running in CRON (non-interactive)
    if [[ ! -t 0 && ! -t 1 ]]; then
        debug_message "Running in non-interactive mode (likely CRON)"
    fi

    # Initialize log
    {
        echo ""
        echo "======================================================"
        echo "* LINKCHECKER RUN STARTED - $(date)"
        echo "* VERSION: $SCRIPT_VERSION"
        echo "* DEBUG: $DEBUG"
        echo "* USER: $(whoami)"
        echo "* PID: $$"
        echo "======================================================"
    } >> "$LOG_FILE" 2>/dev/null || true

    debug_message "Log initialized"

    # Parse command line arguments
    debug_message "Raw arguments: $*"

    # Initialize REMAINING_ARGS
    REMAINING_ARGS=()

    # Parse arguments (populates REMAINING_ARGS)
    parse_arguments "$@"

    debug_message "Parsed arguments: ${REMAINING_ARGS[*]}"

    # Check argument count
    if [[ ${#REMAINING_ARGS[@]} -lt 4 ]]; then
        error_message "Not enough parameters"
        show_usage
        exit 1
    fi

    # Extract parameters
    local base_url="${REMAINING_ARGS[0]}"
    local cms_login_url="${REMAINING_ARGS[1]}"
    local language="${REMAINING_ARGS[2]}"
    local mailto="${REMAINING_ARGS[3]}"

    debug_message "Parameters: URL=$base_url, CMS=$cms_login_url, Lang=$language, Mail=$mailto"

    # Validate parameters
    validate_parameters "$base_url" "$cms_login_url" "$language" "$mailto"

    # Set language
    set_language_texts "$language"

    # Check prerequisites
    check_prerequisites

    # Log start
    log_message "Starting check for: $base_url"
    log_message "Parameters: CMS=$cms_login_url, Language=$language, Recipients=$mailto"
    log_message "Dynamic excludes: ${#DYNAMIC_EXCLUDES[@]}"

    # Run linkchecker
    run_linkchecker "$base_url" || exit 1

    # Process YouTube URLs
    process_youtube_urls

    # Check results
    if [[ "$ERRORS_FOUND" != "true" ]]; then
        log_message "No errors found - no email will be sent"
        log_message "LINKCHECKER RUN COMPLETED - $(date)"
        log_message "======================================================"
        return 0
    fi

    # Generate and send report
    local total_errors=$((ERROR_URLS + YOUTUBE_ERRORS))
    log_message "Found $total_errors total errors ($ERROR_URLS link errors, $YOUTUBE_ERRORS YouTube errors) - generating report"

    local report_file="/tmp/linkchecker_report_$$_$(date +%s).html"
    add_temp_file "$report_file"

    generate_html_report "$base_url" "$cms_login_url" "$language" "$report_file"

    if send_email "$mailto" "$base_url" "$report_file"; then
        log_message "Check completed successfully"
    else
        log_message "Check completed with email sending failure"
    fi

    log_message "LINKCHECKER RUN COMPLETED - $(date)"
    log_message "======================================================"
    return 0
}

#==============================================================================
# Script entry point
#==============================================================================

# Handle help
if [[ "${1:-}" =~ ^(-h|--help)$ ]] || [[ $# -eq 0 ]]; then
    show_usage
    exit 0
fi

# Run main function
main "$@"

# Exit codes:
# 0 - Success (check completed, email sent if errors found)
# 1 - Error (missing parameters, invalid config, or execution failure)
