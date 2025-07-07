#!/bin/bash

#==============================================================================
# Website Linkchecker Script v1.0
# 
# This script runs linkchecker on a website and sends an HTML email report
# if any broken links are found.
#
# Author: LEXO
# Version: 1.0
# Date: 2025-07-03
#==============================================================================

# Configuration
SCRIPT_NAME="LEXO Linkchecker"
SCRIPT_VERSION="1.0"
USER_AGENT="LEXO Linkchecker/1.0"
LOGO_URL="https://www.yourwebsite.ch/your-logo.png"		### recommended max width/height: 300px / 150px
LOG_FILE="/var/log/linkchecker.log"
DEBUG=false  # Set to true to enable debug output

# Email configuration
MAIL_SENDER="your-email@domain.com"
MAIL_SENDER_NAME="Your Sender Name"

# Exclude patterns (REGEX syntax)
# Add regex patterns here to exclude URLs from being checked
# Examples:
#   "\/xmlrpc\.php\b"           - Excludes xmlrpc.php files
#   "\/wp-admin\/"              - Excludes wp-admin paths  
#   "\.pdf$"                    - Excludes PDF files
#   "\/api\/"                   - Excludes API endpoints
#   "\?.*utm_"                  - Excludes URLs with UTM parameters
EXCLUDES=(
    "\/xmlrpc\.php\b"
    # Add more exclude patterns here as needed
)

# Global variables for statistics
TOTAL_URLS=0
ERROR_URLS=0
EXCLUDED_URLS=0
CHECK_DURATION=0
ERRORS_FOUND=false

# Arrays to store error data
declare -a ERROR_URL_LIST
declare -a ERROR_TEXT_LIST
declare -a ERROR_PARENT_LIST

#==============================================================================
# Function: Log message
#==============================================================================
log_message() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" >> "$LOG_FILE"
}

#==============================================================================
# Function: Debug message (only if DEBUG=true)
#==============================================================================
debug_message() {
    if [[ "$DEBUG" == "true" ]]; then
        local message="$1"
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        echo "[$timestamp] DEBUG: $message" >> "$LOG_FILE"
    fi
}

#==============================================================================
# Function: Error message (to CLI and log)
#==============================================================================
error_message() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] ERROR: $message" >> "$LOG_FILE"
    echo "Error: $message" >&2
}

#==============================================================================
# Function: Check if URL should be excluded
#==============================================================================
is_url_excluded() {
    local url="$1"
    
    # Check each exclude pattern
    for pattern in "${EXCLUDES[@]}"; do
        if [[ "$url" =~ $pattern ]]; then
            debug_message "URL excluded by pattern '$pattern': $url"
            return 0  # URL should be excluded
        fi
    done
    
    return 1  # URL should not be excluded
}

#==============================================================================
# Function: Show usage information
#==============================================================================
show_usage() {
    cat << EOF
Usage: $0 <base_url> <cms_login_url> <language> <mailto>

Parameters:
  base_url        Base URL of the website to check
                  Example: https://www.website.tld
  
  cms_login_url   CMS Login URL for the website (use "-" if none)
                  Example: https://www.website.tld/admin
                  Example: -
  
  language        Language for the report (de|en)
                  Example: de
                  Example: en
  
  mailto          Comma-separated list of email addresses
                  Example: admin@website.tld
                  Example: admin@website.tld,webmaster@website.tld

Examples:
  $0 https://www.website.tld https://www.website.tld/admin de admin@website.tld
  $0 https://example.com - en webmaster@example.com,admin@example.com

Requirements:
  - linkchecker must be installed
  - mail command must be available
  - Script must be run with appropriate permissions

EOF
}

#==============================================================================
# Function: Set language-specific texts
#==============================================================================
set_language_texts() {
    local lang="$1"
    
    if [[ "$lang" == "en" ]]; then
        # English texts
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
    else
        # German texts (for "de")
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
    fi
}

#==============================================================================
# Function: Validate parameters
#==============================================================================
validate_parameters() {
    if [[ $# -lt 4 ]]; then
        error_message "Not enough parameters provided."
        show_usage
        exit 1
    fi
    
    local base_url="$1"
    local cms_login_url="$2"
    local language="$3"
    local mailto="$4"
    
    # Validate base URL
    if [[ ! "$base_url" =~ ^https?:// ]]; then
        error_message "Base URL must start with http:// or https://"
        exit 1
    fi
    
    # Validate CMS login URL (if not "-")
    if [[ "$cms_login_url" != "-" ]] && [[ ! "$cms_login_url" =~ ^https?:// ]]; then
        error_message "CMS Login URL must start with http:// or https:// (or use '-' for none)"
        exit 1
    fi
    
    # Validate language
    if [[ "$language" != "de" ]] && [[ "$language" != "en" ]]; then
        error_message "Language must be 'de' or 'en'"
        exit 1
    fi
    
    # Validate email addresses
    if [[ ! "$mailto" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(,[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})*$ ]]; then
        error_message "Invalid email address format"
        exit 1
    fi
}

#==============================================================================
# Function: Check prerequisites
#==============================================================================
check_prerequisites() {
    # Check if linkchecker is installed
    if ! command -v linkchecker &> /dev/null; then
        error_message "linkchecker is not installed or not in PATH"
        exit 1
    fi
    
    # Check if mail command is executable
    if ! command -v mail &> /dev/null; then
        error_message "mail command is not executable or not in PATH"
        exit 1
    fi
    
    # Ensure log file is writable
    if ! touch "$LOG_FILE" 2>/dev/null; then
        error_message "Cannot write to log file $LOG_FILE"
        exit 1
    fi
}

#==============================================================================
# Function: Run linkchecker and parse results
#==============================================================================
run_linkchecker() {
    local base_url="$1"
    local start_time=$(date +%s)
    
    log_message "Starting linkchecker on $base_url"
    debug_message "Running linkchecker command..."
    
    # Run linkchecker and capture all output in memory
    local raw_output
    raw_output=$(sudo -u www-data linkchecker \
        --user-agent="$USER_AGENT" \
        --check-extern \
        --recursion-level=10 \
        --timeout=30 \
        --threads=20 \
        --output=csv \
        "$base_url" 2>&1)
    
    local linkchecker_exit_code=$?
    local end_time=$(date +%s)
    CHECK_DURATION=$((end_time - start_time))
    
    debug_message "linkchecker exit code: $linkchecker_exit_code"
    debug_message "Raw output length: ${#raw_output} characters"
    debug_message "Raw output line count: $(echo "$raw_output" | wc -l)"
    
    # Log linkchecker output based on debug mode
    if [[ "$DEBUG" == "true" ]]; then
        log_message "Raw linkchecker output (complete):"
        echo "$raw_output" >> "$LOG_FILE"
    fi
    
    # Check linkchecker exit code
    if [[ $linkchecker_exit_code -ne 0 ]] && [[ $linkchecker_exit_code -ne 1 ]]; then
        error_message "linkchecker failed with exit code $linkchecker_exit_code"
        log_message "linkchecker stderr output: $raw_output"
        exit 1
    fi
    
    log_message "Linkchecker completed in ${CHECK_DURATION} seconds"
    
    # Process output using readarray to avoid subshell issues
    debug_message "Starting to process linkchecker output..."
    
    # Write output to temp file and read into array
    local temp_file="/tmp/linkchecker_lines_$.txt"
    printf '%s\n' "$raw_output" > "$temp_file"
    
    debug_message "Processing linkchecker output file: $temp_file"
    debug_message "File size: $(wc -l < "$temp_file") lines"
    
    # Reset counters
    TOTAL_URLS=0
    ERROR_URLS=0
    EXCLUDED_URLS=0
    ERRORS_FOUND=false
    ERROR_URL_LIST=()
    ERROR_TEXT_LIST=()
    ERROR_PARENT_LIST=()
    
    debug_message "Reset all counters and arrays"
    
    # Read file into array to avoid any subshell issues
    local -a lines
    readarray -t lines < "$temp_file"
    
    debug_message "Read ${#lines[@]} lines into array"
    
    # Process each line from array
    local line_number=0
    local csv_header_found=false
    
    for line in "${lines[@]}"; do
        line_number=$((line_number + 1))
        
        # Skip empty lines
        if [[ -z "$line" ]]; then
            continue
        fi
        
        # Skip comment lines
        if [[ "$line" =~ ^#.*$ ]]; then
            continue
        fi
        
        # Skip progress lines
        if [[ "$line" =~ thread.*queued|Verknüpfungen|URLs.*checked ]]; then
            continue
        fi
        
        # Check for CSV header
        if [[ "$line" =~ ^urlname\; ]]; then
            debug_message "Found CSV header at line $line_number"
            csv_header_found=true
            continue
        fi
        
        # Check if this is a CSV data line (has multiple semicolons)
        if [[ "$line" =~ ^https?://.*\;.*\;.*\;.*\; ]]; then
            # Parse CSV fields
            IFS=';' read -r url_name parent_url base_ref result warning_string info_string valid real_url line_num column name_dl_time_dl_size check_time <<< "$line"
            
            debug_message "Processing URL: $url_name"
            
            # Check if URL should be excluded
            if is_url_excluded "$url_name"; then
                EXCLUDED_URLS=$((EXCLUDED_URLS + 1))
                debug_message "URL excluded, skipping: $url_name"
                continue  # Skip this URL
            fi
            
            # Count total URLs (only non-excluded ones)
            TOTAL_URLS=$((TOTAL_URLS + 1))
            debug_message "URL added to check list: $url_name"
            
            # Check if this is an error
            local is_error=false
            local error_text=""
            
            # Check for HTTP error status codes
            if [[ "$result" =~ ^[0-9]+$ ]]; then
                if [[ "$result" -ge 400 ]]; then
                    error_text="HTTP $result"
                    is_error=true
                fi
            elif [[ "$result" =~ ^[0-9]+[[:space:]].* ]]; then
                # Handle "404 Not Found" format
                local status_code=$(echo "$result" | cut -d' ' -f1)
                if [[ "$status_code" -ge 400 ]]; then
                    error_text="$result"
                    is_error=true
                fi
            elif [[ "$result" =~ Timeout ]]; then
                error_text="$LANG_TIMEOUT_ERROR"
                is_error=true
            elif [[ "$result" =~ Error|Failed ]]; then
                error_text="$result"
                is_error=true
            fi
            
            # Store error data
            if [[ "$is_error" == true ]]; then
                debug_message "Error found: $url_name -> $error_text"
                ERROR_URL_LIST+=("$url_name")
                ERROR_TEXT_LIST+=("$error_text")
                ERROR_PARENT_LIST+=("$parent_url")
                ERROR_URLS=$((ERROR_URLS + 1))
                ERRORS_FOUND=true
            fi
        fi
    done
    
    # Clean up temp file
    rm -f "$temp_file"
    
    debug_message "Finished processing linkchecker output"
    debug_message "Final counts: TOTAL_URLS=$TOTAL_URLS, ERROR_URLS=$ERROR_URLS, EXCLUDED_URLS=$EXCLUDED_URLS, ERRORS_FOUND=$ERRORS_FOUND"
    log_message "Results: $TOTAL_URLS URLs checked, $ERROR_URLS errors found, $EXCLUDED_URLS URLs excluded"
}

#==============================================================================
# Function: Generate HTML email report
#==============================================================================
generate_html_report() {
    local base_url="$1"
    local cms_login_url="$2"
    local language="$3"
    local mail_html="$4"
    
    # Calculate success rate
    local success_rate=100
    if [[ $TOTAL_URLS -gt 0 ]]; then
        success_rate=$(( (TOTAL_URLS - ERROR_URLS) * 100 / TOTAL_URLS ))
    fi
    
    # Format duration
    local duration_formatted="${CHECK_DURATION}s"
    if [[ $CHECK_DURATION -ge 60 ]]; then
        local minutes=$((CHECK_DURATION / 60))
        local seconds=$((CHECK_DURATION % 60))
        duration_formatted="${minutes}m ${seconds}s"
    fi
    
    # Start generating HTML
    cat > "$mail_html" << EOF
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$LANG_SUBJECT</title>
    <style>
        body {
            font-family: 'Century Gothic', Arial, sans-serif;
            margin: 0;
            padding: 10px;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 100%;
            margin: 0 auto;
            background-color: white;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .header {
            text-align: center;
            margin-bottom: 30px;
        }
        .logo {
            max-width: 200px;
            height: auto;
            margin-bottom: 20px;
        }
        h1 {
            color: #2c3e50;
            margin-bottom: 10px;
            font-size: 22px;
        }
        h2 {
            color: #34495e;
            margin-top: 30px;
            margin-bottom: 15px;
            font-size: 16px;
            border-bottom: 2px solid #3498db;
            padding-bottom: 5px;
        }
        .intro {
            background-color: #ecf0f1;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
            font-size: 14px;
        }
        .intro a {
            color: #2980b9;
            text-decoration: none;
        }
        .intro a:hover {
            text-decoration: underline;
        }
        .cms-link {
            background-color: #e8f5e8;
            padding: 10px;
            border-radius: 5px;
            margin-bottom: 20px;
            font-size: 14px;
        }
        .cms-link h2 {
            margin-top: 0;
            margin-bottom: 10px;
        }
        .cms-link a {
            color: #27ae60;
            text-decoration: none;
            font-weight: bold;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
            font-size: 12px;
        }
        th, td {
            padding: 8px;
            text-align: left;
            border-bottom: 1px solid #ddd;
            word-wrap: break-word;
        }
        th {
            background-color: #3498db;
            color: white;
            font-weight: bold;
            font-size: 13px;
        }
        .summary-table th:first-child {
            width: 300px;
            min-width: 300px;
        }
        .summary-table {
            background-color: #f8f9fa;
            font-size: 14px;
            table-layout: fixed;
        }
        .summary-table th {
            background-color: #6c757d;
            font-size: 14px;
        }
        .summary-table td {
            font-size: 14px;
        }
        .error-table tr:nth-child(even) {
            background-color: #f2f2f2;
        }
        .error-table tr:nth-child(odd) {
            background-color: #ffffff;
        }
        .url-cell {
            word-break: break-all;
            max-width: 40%;
            font-size: 11px;
        }
        .url-cell a {
            color: #2980b9;
            text-decoration: none;
        }
        .url-cell a:hover {
            text-decoration: underline;
        }
        .error-cell {
            color: #e74c3c;
            font-weight: bold;
            font-size: 12px;
        }
        .footer {
            text-align: center;
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #ddd;
            font-size: 11px;
            color: #7f8c8d;
        }
        .success-rate {
            color: #27ae60;
            font-weight: bold;
        }
        .error-count {
            color: #e74c3c;
            font-weight: bold;
        }
        /* Responsive design */
        @media screen and (max-width: 600px) {
            .container {
                padding: 10px;
            }
            h1 {
                font-size: 18px;
            }
            h2 {
                font-size: 14px;
            }
            table {
                font-size: 10px;
            }
            th, td {
                padding: 6px;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <img src="$LOGO_URL" alt="Logo" class="logo">
            <h1>$LANG_INTRO_TITLE</h1>
        </div>
        
        <div class="intro">
            <p>$LANG_INTRO_TEXT <a href="$base_url">$base_url</a>. 
EOF
    
    # Add language-specific ending text
    if [[ "$language" == "en" ]]; then
        cat >> "$mail_html" << EOF
Please review this report and fix the issues.</p>
EOF
    else
        cat >> "$mail_html" << EOF
Bitte prüfen Sie den vorliegenden Bericht und beheben Sie die Probleme.</p>
EOF
    fi
    
    cat >> "$mail_html" << EOF
        </div>
EOF

    # Add CMS login link if provided
    if [[ "$cms_login_url" != "-" ]]; then
        cat >> "$mail_html" << EOF
        <div class="cms-link">
            <h2>$LANG_CMS_TITLE</h2>
            <p style="margin: 0;">$LANG_CMS_TEXT <a href="$cms_login_url">$cms_login_url</a></p>
        </div>
EOF
    fi

    # Add summary table
    cat >> "$mail_html" << EOF
        <h2>$LANG_SUMMARY_TITLE</h2>
        <table class="summary-table">
            <tr>
                <th>$LANG_DURATION</th>
                <td>$duration_formatted</td>
            </tr>
            <tr>
                <th>$LANG_TOTAL_URLS</th>
                <td>$TOTAL_URLS</td>
            </tr>
            <tr>
                <th>$LANG_ERROR_URLS</th>
                <td class="error-count">$ERROR_URLS</td>
            </tr>
            <tr>
                <th>$LANG_SUCCESS_RATE</th>
                <td class="success-rate">${success_rate}%</td>
            </tr>
        </table>
        
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

    # Add error entries from arrays
    for i in "${!ERROR_URL_LIST[@]}"; do
        cat >> "$mail_html" << EOF
                <tr>
                    <td class="url-cell"><a href="${ERROR_URL_LIST[$i]}" style="color: #2980b9; text-decoration: none;">${ERROR_URL_LIST[$i]}</a></td>
                    <td class="error-cell">${ERROR_TEXT_LIST[$i]}</td>
                    <td class="url-cell"><a href="${ERROR_PARENT_LIST[$i]}" style="color: #2980b9; text-decoration: none;">${ERROR_PARENT_LIST[$i]}</a></td>
                </tr>
EOF
    done

    # Close HTML
    cat >> "$mail_html" << EOF
            </tbody>
        </table>
        
        <div class="footer">
            <p>Dieser Bericht wurde automatisch am $(date '+%d.%m.%Y, %H:%M:%S') vom $SCRIPT_NAME generiert.</p>
        </div>
    </div>
</body>
</html>
EOF
}

#==============================================================================
# Function: Send email report
#==============================================================================
send_email_report() {
    local mailto="$1"
    local base_url="$2"
    local mail_html="$3"
    
    # Extract domain from URL for subject
    local domain=$(echo "$base_url" | sed 's|https\?://||' | sed 's|/.*||')
    local subject="$LANG_SUBJECT - $domain"
    
    log_message "Sending email report to: $mailto"
    debug_message "Email subject: $subject"
    debug_message "Email HTML file: $mail_html"
    
    # Send email using mail command
    if sudo -u "$MAIL_SENDER" mail \
        -s "$subject" \
        -a "Content-Type: text/html; charset=UTF-8" \
        -a "Content-Transfer-Encoding: 8bit" \
        -a "From: $MAIL_SENDER_NAME <$MAIL_SENDER>" \
        "$mailto" < "$mail_html" 2>>"$LOG_FILE"; then
        log_message "Email report sent successfully"
    else
        error_message "Failed to send email"
        exit 1
    fi
}

#==============================================================================
# Function: Main execution
#==============================================================================
main() {
    # Initialize log with clear marker - THIS SHOULD ALWAYS APPEAR
    echo "" >> "$LOG_FILE"
    echo "******************************************************" >> "$LOG_FILE"
    echo "* NEW LINKCHECKER CYCLE STARTED - $(date)" >> "$LOG_FILE"
    echo "* SCRIPT VERSION: $SCRIPT_VERSION" >> "$LOG_FILE"
    echo "* DEBUG MODE: $DEBUG" >> "$LOG_FILE"
    echo "******************************************************" >> "$LOG_FILE"
    
    # Validate parameters
    validate_parameters "$@"
    
    # Extract parameters
    local base_url="$1"
    local cms_login_url="$2"
    local language="$3"
    local mailto="$4"
    
    # Set language texts
    set_language_texts "$language"
    
    # Check prerequisites
    check_prerequisites
    
    # Log execution details
    log_message "Starting $SCRIPT_NAME v$SCRIPT_VERSION"
    log_message "Parameters: URL=$base_url, CMS=$cms_login_url, Lang=$language, Mail=$mailto"
    log_message "Debug mode: $DEBUG"
    log_message "Log file: $LOG_FILE"
    debug_message "User agent: $USER_AGENT"
    debug_message "Logo URL: $LOGO_URL"
    debug_message "Mail sender: $MAIL_SENDER_NAME <$MAIL_SENDER>"
    
    # Run linkchecker and parse results
    run_linkchecker "$base_url"
    
    # Check if errors were found
    if [[ "$ERRORS_FOUND" != "true" ]]; then
        log_message "No errors found - no email will be sent"
        log_message "SUMMARY: Check completed successfully. $TOTAL_URLS URLs checked, 0 errors found, $EXCLUDED_URLS URLs excluded."
        log_message "******************************************************"
        exit 0
    fi
    
    log_message "SUMMARY: Errors found - generating email report"
    log_message "Total URLs checked: $TOTAL_URLS"
    log_message "URLs with errors: $ERROR_URLS"
    log_message "URLs excluded: $EXCLUDED_URLS"
    log_message "Error URLs: ${ERROR_URL_LIST[*]}"
    
    # Generate HTML report using a temp file (minimal file usage)
    local temp_html="/tmp/linkchecker_report_$$.html"
    generate_html_report "$base_url" "$cms_login_url" "$language" "$temp_html"
    
    # Send email report
    send_email_report "$mailto" "$base_url" "$temp_html"
    
    # Clean up temp file
    rm -f "$temp_html"
    
    log_message "SUMMARY: Link check completed successfully. Email report sent to $mailto"
    log_message "******************************************************"
}

#==============================================================================
# Script execution starts here
#==============================================================================

# Check if help is requested
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]] || [[ $# -eq 0 ]]; then
    show_usage
    exit 0
fi

# Run main function with all parameters
main "$@"