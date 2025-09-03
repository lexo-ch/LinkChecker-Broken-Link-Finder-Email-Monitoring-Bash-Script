#!/bin/bash

# Ensure the script runs with bash even if invoked via sh
if [ -z "${BASH_VERSION:-}" ]; then
  exec /bin/bash "$0" "$@"
fi

#==============================================================================
# LEXO Website Linkchecker Script - Comprehensive Website Health Monitor
#==============================================================================
#
# OVERVIEW
# --------
# This script provides enterprise-grade website link validation with advanced
# capabilities to overcome modern web protection mechanisms. It performs
# comprehensive crawling, link checking, and generates professional HTML email
# reports for website maintenance teams.
#
# CORE FUNCTIONALITY
# ------------------
# 1. Website Crawling: Intelligently discovers all internal links by crawling
#    HTML pages, CSS files, and extracting URLs from various HTML attributes
#    (href, src, action, poster, srcset) and any additional custom attributes
#    defined in CUSTOM_ATTR_INCLUDES while respecting depth and URL limits.
#
# 2. Link Validation: Performs parallel HTTP requests to validate discovered
#    links, detecting broken links, server errors, and unreachable resources.
#    Uses optimized HEAD requests for efficiency with GET fallback when needed.
#
# 3. Multi-Format Support: Extracts and validates links from:
#    - HTML pages (all standard link attributes)
#    - CSS stylesheets (url() declarations)
#    - YouTube videos (via oEmbed API with rate limiting and retry logic)
#    - Various media and document formats
#
# 4. Professional Reporting: Generates branded HTML email reports with
#    comprehensive statistics, error details, and actionable insights for
#    website administrators.
#
# WHY CURL-IMPERSONATE?
# ---------------------
# Modern websites employ sophisticated protection mechanisms that block
# traditional automated tools:
#
# • CDN Protection: Services like Cloudflare, AWS CloudFront actively
#   fingerprint and block non-browser requests
# • WAF Filtering: Web Application Firewalls detect and reject bot traffic
#   based on HTTP headers, TLS fingerprints, and request patterns
# • Bot Detection: Advanced JavaScript-based detection systems analyze
#   browser behavior patterns
# • Rate Limiting: Aggressive throttling of requests from non-browser agents
#
# curl-impersonate solves these challenges by:
# - Mimicking real Chrome browser TLS fingerprints and HTTP/2 behavior
# - Using authentic browser headers and connection patterns
# - Supporting modern web standards (HTTP/2, ALPS, certificate compression)
# - Bypassing most bot detection mechanisms through browser emulation
# - Intelligent protection detection for Cloudflare and similar services
#
# This approach ensures reliable access to protected websites that would
# otherwise reject standard curl or wget requests, making the linkchecker
# effective against modern web infrastructure.
#
# PERFORMANCE OPTIMIZATIONS
# --------------------------
# • Parallel Processing: Configurable worker pools for concurrent URL checking
# • Connection Pooling: Reuses HTTP connections to reduce overhead
# • Batch Processing: Groups URL checks to optimize resource utilization
# • Smart Caching: Avoids duplicate checks of identical URLs
# • Memory Optimization: Uses associative arrays for O(1) lookups
# • Single-Pass Parsing: Efficient HTML/CSS parsing using optimized awk scripts
# • Intelligent HTTP Methods: Uses GET for external URLs and HEAD for internal
#   URLs with automatic fallback for servers that reject HEAD requests
# • YouTube Retry Logic: Automatic retry with exponential backoff for YouTube
#   oEmbed API checks to reduce false positives from temporary API issues
#
# CUSTOMIZABLE EMAIL REPORTING SYSTEM
# ------------------------------------
# The script features a comprehensive white-label email system designed for
# professional website maintenance services:
#
# Brand Customization:
# - Custom logos, colors, and organizational branding
# - Configurable sender information and mail headers
# - Professional HTML templates with responsive design
#
# Multi-Language Support:
# - German and English language templates
# - Placeholder system for dynamic content insertion
# - Localized error messages and technical terminology
#
# Report Features:
# - Executive summary with key metrics and success rates
# - Detailed error breakdown with clickable links
# - Context-aware parent page information
# - CSS-specific error highlighting
# - YouTube video availability checking
# - CMS login integration for immediate action
#
# Statistical Analysis:
# - Success rates and performance metrics
# - Duplicate error detection and false positive filtering
# - Check duration and throughput statistics
# - Comprehensive URL discovery and validation counts
#
# The reporting system transforms technical link checking data into
# actionable business intelligence, enabling website administrators to
# quickly identify and prioritize website maintenance tasks.
#
# ENTERPRISE FEATURES
# -------------------
# • Flexible Configuration: Extensive command-line options and environment
#   variable support for integration into automated workflows
# • Robust Error Handling: Comprehensive logging with timestamp and domain
#   context for troubleshooting and audit trails
# • Scalability Controls: Configurable limits for depth, URL count, and
#   parallel processing to manage resource consumption
# • Integration Ready: Designed for cron jobs, CI/CD pipelines, and
#   automated monitoring systems
# • Security Conscious: Respects robots.txt conventions and implements
#   rate limiting to avoid overwhelming target servers
# • Protection Detection: Intelligent detection of CDN/WAF protection with
#   configurable exclusion from error reports to reduce false positives
# • URL Normalization: Advanced URL parsing and normalization for accurate
#   link discovery across different URL formats and encodings
#
# TYPICAL USE CASES
# -----------------
# 1. Automated Website Maintenance: Regular link checking for content teams
# 2. SEO Optimization: Identifying broken links that impact search rankings
# 3. Website Migration: Validating link integrity after site moves
# 4. Client Reporting: Professional reports for web development agencies
# 5. Compliance Monitoring: Ensuring website accessibility and functionality
#
# Author:   LEXO
#==============================================================================

#==============================================================================
# BRANDING & WHITE-LABEL CONFIGURATION
#==============================================================================
# Change these values to customize the script for your organization

SCRIPT_NAME="YOURCOMPANY Linkchecker"
SCRIPT_VERSION="2.6.4"
LOGO_URL="https://www.YOURCOMPANY.ch/brandings/YOURCOMPANY-Logo.png"
LOGO_ALT="YOURCOMPANY Linkchecker Logo"  # Alt text for logo image
MAIL_SENDER="support@yourcompany.tld"
MAIL_SENDER_NAME="YOURCOMPANY Support"

# Theme Color Configuration
# Change this single variable to customize the primary color throughout the report
# Default: #832883 (purple)
THEME_COLOR="#832883"

#==============================================================================
# LANGUAGE TEMPLATES - GERMAN
#==============================================================================
# Customize these texts for your email reports
# Available placeholders:
#   ###base_url### - The checked website URL
#   ###cms_url###  - The CMS login URL
#   ###max_urls### - The MAX_URLS limit value
#   ###crawled_count### - Number of URLs crawled when MAX_URLS was reached
#   ###discovered_count### - Total URLs discovered when MAX_URLS was reached

LANG_DE_SUBJECT="Defekte Links auf der Website gefunden"
LANG_DE_INTRO_TITLE="Fehlerhafte Links auf Ihrer Webseite entdeckt"
LANG_DE_INTRO_TEXT="Die automatische Überprüfung Ihrer Webseite ###base_url### hat fehlerhafte Links erkannt. Bitte prüfen Sie den beigefügten Bericht. Die Behebung dieser Probleme erhöht die Qualität Ihrer Webseite.<br><br>Auf Wunsch unterstützen wir Sie bei der Korrektur (Verrechnung nach Aufwand).<br><br>Wir empfehlen, die Anpassungen selbst vorzunehmen, da der Kontext der Links oft nur Ihnen bekannt ist. Es kann unklar sein, ob ein Link entfernt, geändert oder z. B. als PDF lokal hochgeladen werden sollte, was häufig Rückfragen erfordert."
LANG_DE_CMS_TITLE="CMS Login"
LANG_DE_CMS_TEXT="Für das Beheben der Probleme können Sie sich unter folgendem Link einloggen: ###cms_url###"
LANG_DE_SUMMARY_TITLE="Zusammenfassung"
LANG_DE_DETAILS_TITLE="Detaillierter Fehlerbericht"
LANG_DE_DURATION="Überprüfungsdauer"
LANG_DE_TOTAL_URLS="Anzahl überprüfter URLs"
LANG_DE_ERROR_URLS="URLs mit Fehlern"
LANG_DE_DUPLICATE_ERRORS="Fehler doppelt geprüft"
LANG_DE_FALSE_POSITIVES="Falsch-Positive entfernt"
LANG_DE_YOUTUBE_CHECKED="YouTube URLs überprüft"
LANG_DE_YOUTUBE_UNAVAILABLE="YouTube Videos nicht verfügbar"
LANG_DE_SUCCESS_RATE="Erfolgsrate"
LANG_DE_COLUMN_URL="Fehlerhafte URL"
LANG_DE_COLUMN_ERROR="Fehler"
LANG_DE_COLUMN_PARENT="Gefunden auf Seite"
LANG_DE_FOOTER_TEXT="Generiert vom YOURCOMPANY Linkchecker"
LANG_DE_CSS_NOTE="Orange Zeilen zeigen Fehler aus CSS-Dateien"
LANG_DE_PROTECTION_TITLE="Seitenschutz erkannt - was bedeutet das?"
LANG_DE_PROTECTION_TEXT="Einige Webseiten verwenden Schutzmechanismen (z.B. Cloudflare), die automatische Überprüfungen blockieren. Diese Seiten erscheinen als Fehler, sind aber für normale Besucher erreichbar. Sie müssen diese Links manuell im Browser überprüfen. Keinen Bericht mehr für Seitenschutz-Fehler erhalten? Antworten Sie auf diese E-Mail und teilen Sie uns dies kurz mit."
LANG_DE_PROTECTION_DETECTED="(Seitenschutz erkannt)"
LANG_DE_MAX_URLS_SUBJECT="Linkchecker hat die maximale URL-Grenze erreicht"
LANG_DE_MAX_URLS_TITLE="Maximale URL-Grenze erreicht"
LANG_DE_MAX_URLS_TEXT="Die automatische Überprüfung Ihrer Webseite ###base_url### musste nach Erreichen der maximalen URL-Grenze von ###max_urls### URLs gestoppt werden. Dies kann auf ein Problem mit der Website-Struktur hinweisen (z.B. Endlosschleifen, dynamische URL-Generierung oder sehr große Sitemaps).<br><br>Die Überprüfung wurde bei URL Nummer ###crawled_count### während des Crawlings gestoppt. Insgesamt wurden ###discovered_count### URLs entdeckt.<br><br>Empfohlene Maßnahmen:<br>• Überprüfen Sie die Website-Struktur auf Endlosschleifen<br>• Prüfen Sie dynamisch generierte URLs<br>• Erwägen Sie, das URL-Limit zu erhöhen oder spezifische Bereiche auszuschließen"
LANG_DE_URL_LOOP_TITLE="Achtung: Mögliche URL-Endlosschleife erkannt!"
LANG_DE_URL_LOOP_TEXT="Auf Ihrer Webseite wurden URLs mit sich wiederholenden Mustern gefunden. Dies deutet auf ein technisches Problem hin, bei dem sich Links immer wieder selbst aufrufen, oder auf eine für Suchmaschinen (SEO) ungünstige Linkstruktur.<br><br><strong>Was bedeutet das für Sie?</strong><br>• Ihre Webseite könnte für Besucher verwirrend sein<br>• Suchmaschinen (wie Google) könnten Ihre Seite schlechter bewerten<br>• Die Webseite könnte langsamer werden<br>• Ihr Suchmaschinen-Ranking könnte sich verschlechtern<br><br><strong>Was sollten Sie tun?</strong><br>Überprüfen Sie die unten aufgelisteten URLs und passen Sie die Linkstruktur Ihrer Webseite an. Das Problem sollte zeitnah behoben werden, um die Funktionalität und Sichtbarkeit Ihrer Webseite zu gewährleisten. Bei Fragen können Sie sich gerne an uns wenden."
LANG_DE_URL_LOOP_SUBJECT_SUFFIX=" - Potenzielle URL-Endlosschleife erkannt"
LANG_DE_URL_LOOP_TABLE_HEADER="URLs mit wiederholendem Muster"

#==============================================================================
# LANGUAGE TEMPLATES - ENGLISH
#==============================================================================
# Available placeholders:
#   ###base_url### - The checked website URL
#   ###cms_url###  - The CMS login URL
#   ###max_urls### - The MAX_URLS limit value
#   ###crawled_count### - Number of URLs crawled when MAX_URLS was reached
#   ###discovered_count### - Total URLs discovered when MAX_URLS was reached

LANG_EN_SUBJECT="Broken Links Found on Website"
LANG_EN_INTRO_TITLE="Broken Links Discovered on Your Website"
LANG_EN_INTRO_TEXT="The automated check of your website ###base_url### detected broken links. Please review the attached report. Fixing these issues will improve the quality of your website.<br><br>Upon request, we can assist with the corrections (charged based on effort).<br><br>We recommend making the adjustments yourself, as the context of the links is often only known to you. It may be unclear whether a link should be removed, modified, or, for example, saved as a PDF and uploaded locally, which frequently requires clarification."
LANG_EN_CMS_TITLE="CMS Login"
LANG_EN_CMS_TEXT="To fix these issues, you can log in at: ###cms_url###"
LANG_EN_SUMMARY_TITLE="Summary"
LANG_EN_DETAILS_TITLE="Detailed Error Report"
LANG_EN_DURATION="Check Duration"
LANG_EN_TOTAL_URLS="Total URLs Checked"
LANG_EN_ERROR_URLS="URLs with Errors"
LANG_EN_DUPLICATE_ERRORS="Duplicate Errors Checked"
LANG_EN_FALSE_POSITIVES="False Positives Removed"
LANG_EN_YOUTUBE_CHECKED="YouTube URLs Checked"
LANG_EN_YOUTUBE_UNAVAILABLE="YouTube Videos Unavailable"
LANG_EN_SUCCESS_RATE="Success Rate"
LANG_EN_COLUMN_URL="Broken URL"
LANG_EN_COLUMN_ERROR="Error"
LANG_EN_COLUMN_PARENT="Found on Page"
LANG_EN_FOOTER_TEXT="Generated by YOURCOMPANY Linkchecker"
LANG_EN_CSS_NOTE="Orange rows show errors from CSS files"
LANG_EN_PROTECTION_TITLE="Page protection detected - what does this mean?"
LANG_EN_PROTECTION_TEXT="Some websites use protection mechanisms (e.g., Cloudflare) that block automated checks. These pages appear as errors but are accessible to normal visitors. You need to manually check these links in your browser. You do not want to receive reports about page protection errors anymore? Please answer on this email and let us know about it."
LANG_EN_PROTECTION_DETECTED="(page protection detected)"
LANG_EN_MAX_URLS_SUBJECT="Linkchecker reached maximum URL limit"
LANG_EN_MAX_URLS_TITLE="Maximum URL Limit Reached"
LANG_EN_MAX_URLS_TEXT="The automated check of your website ###base_url### had to be stopped after reaching the maximum URL limit of ###max_urls### URLs. This may indicate an issue with the website structure (e.g., infinite loops, dynamic URL generation, or very large sitemaps).<br><br>The check was stopped at URL number ###crawled_count### during crawling. A total of ###discovered_count### URLs were discovered.<br><br>Recommended actions:<br>• Check the website structure for infinite loops<br>• Review dynamically generated URLs<br>• Consider increasing the URL limit or excluding specific areas"
LANG_EN_URL_LOOP_TITLE="Warning: Potential URL Infinite Loop Detected!"
LANG_EN_URL_LOOP_TEXT="URLs with repeating patterns have been found on your website. This indicates a technical issue where links are repeatedly calling themselves, or an unfavorable link structure for search engine optimization (SEO).<br><br><strong>What does this mean for you?</strong><br>• Your website might be confusing for visitors<br>• Search engines (like Google) might rate your site lower<br>• The website might become slower<br>• Your search engine ranking could deteriorate<br><br><strong>What should you do?</strong><br>Review the URLs listed below and adjust your website's link structure. The issue should be resolved promptly to ensure your website's functionality and visibility. If you have any questions, feel free to contact us."
LANG_EN_URL_LOOP_SUBJECT_SUFFIX=" - Potential URL Infinite Loop Detected"
LANG_EN_URL_LOOP_TABLE_HEADER="URLs with Detected Loops"

#==============================================================================
# TECHNICAL CONFIGURATION
#==============================================================================

# Logging
LOG_FILE="${LOG_FILE:-/var/log/linkchecker.log}"
DEBUG="${DEBUG:-false}"

# Performance Settings
PARALLEL_WORKERS="${PARALLEL_WORKERS:-20}"  # Number of parallel URL checks
BATCH_SIZE="${BATCH_SIZE:-50}"              # URLs to process per batch
CONNECTION_CACHE_SIZE="${CONNECTION_CACHE_SIZE:-10000}"  # Curl connection cache

# Protection Detection Settings
INCLUDE_PROTECTED_IN_REPORT="${INCLUDE_PROTECTED_IN_REPORT:-true}"  # Set to false to exclude protected pages from email reports

# CSS Error Handling
# When CSS files contain broken links, these require developer intervention rather than
# customer action. Enable this feature to automatically redirect reports containing
# CSS errors to the web administrator instead of the customer.
REDIRECT_CSS_ERRORS_TO_ADMIN="${REDIRECT_CSS_ERRORS_TO_ADMIN:-true}"  # Redirect reports with CSS errors to admin
CSS_ERROR_ADMIN_EMAIL="${CSS_ERROR_ADMIN_EMAIL:-yoursupportmail@yourcompany.tld}"  # Admin email for CSS error reports

# HTTP Settings
CHECK_METHOD="${CHECK_METHOD:-HEAD}"
CRAWL_METHOD="GET"
CURL_TIMEOUT=15
CURL_MAX_REDIRECTS=10
REQUEST_DELAY="${REQUEST_DELAY:-0}"

# Paths
SENDMAIL_BINARY="/usr/sbin/sendmail"
CURL_IMPERSONATE_BINARY="${CURL_IMPERSONATE_BINARY:-./curl/curl-impersonate-chrome}"

# URL Limits. "-1" = unlimited. Recommended to set a limit to prevent problems in case of an endless URL loop
MAX_DEPTH="${MAX_DEPTH:-50}"
MAX_URLS="${MAX_URLS:-5000}"
MAX_URL_LENGTH="${MAX_URL_LENGTH:-2000}"  # Maximum URL length to process

# URL Loop Detection Settings
# These settings help identify problematic URL structures that indicate infinite loops or 
# poor site architecture. The detection algorithm checks for:
# 1. Consecutive repetitions: /page/page/page/ (same segment repeating)
# 2. Pattern repetitions: /A/B/A/B/A/B/ (pattern of segments repeating)
# 3. Suspicious repetitions: Multiple instances with regular intervals suggesting loops
# When loops are detected, a warning is added to the report with examples and the email
# subject is modified to alert administrators about potential SEO and usability issues.
#
# URL_LOOP_THRESHOLD: How many times a segment/pattern must repeat to be flagged as a loop
#   - Value of 2: Flags /home/home/ or /about/services/about/services/ (2 repetitions)
#   - Value of 3: Only flags /home/home/home/ or patterns repeating 3+ times
#   - Lower values (2) catch more potential issues but may have false positives
#   - Higher values (4-5) reduce false positives but might miss some loops
URL_LOOP_THRESHOLD="${URL_LOOP_THRESHOLD:-2}"  # Number of repetitions to consider as a loop
#
# URL_LOOP_MIN_SEGMENTS: Minimum path segments required before checking for loops
#   - Value of 3: Only checks URLs with 3+ segments like /a/b/c/ (ignores /a/ or /a/b/)
#   - Value of 4: Only checks URLs with 4+ segments like /a/b/c/d/
#   - This prevents false positives on short URLs where repetition might be intentional
#   - Example: With value 3, /products/products/ won't be checked (only 2 segments)
#            but /products/category/products/ will be checked (3 segments)
URL_LOOP_MIN_SEGMENTS="${URL_LOOP_MIN_SEGMENTS:-2}"  # Minimum URL segments to check for loops
#
# URL_LOOP_ENABLE_WARNING: Enable URL loop warning in reports
#   - Set to true to show URL loop warnings in reports (default)
#   - Set to false if you have intentional URL patterns that trigger false positives
URL_LOOP_ENABLE_WARNING="${URL_LOOP_ENABLE_WARNING:-true}"  # Enable URL loop warning box

# MAX_URLS Notification Settings
SEND_REPORT_ON_MAX_URLS_REACHED="${SEND_REPORT_ON_MAX_URLS_REACHED:-true}"  # Send notification when MAX_URLS is reached
MAX_URLS_ADMIN_EMAIL="${MAX_URLS_ADMIN_EMAIL:-yoursupportmail@yourcompany.tld}"  # Email for MAX_URLS notifications

# YouTube
YOUTUBE_DOMAINS='youtube\.com|youtu\.be|youtube-nocookie\.com|yt\.be'
YOUTUBE_OEMBED_DELAY=1
YOUTUBE_MAX_RETRIES="${YOUTUBE_MAX_RETRIES:-3}"  # Maximum retry attempts for YouTube API checks

# Exclude patterns
EXCLUDES=(
    "\/xmlrpc\.php"
    "\/wp-json\/"
    "\/feed\/"
    "\?p=[0-9]+"
    "bootstrap\.min\.css"
    "googletagmanager\.com"
    "(google\.com|goo\.gl)\/(recaptcha|maps)"
    "bootstrap\.css"
    "bootstrap\.min\.css"
    "leaflet\.css"
    "acf-osm-leaflet\.css"
    "owl\.carousel\.css"
    "advanced-slider-base\.css"
    "https:\/\/(www\.)?linkedin\.com"
    "jquery\.bxslider\.css"
    "jquery\.mCustomScrollbar\.css"
    "jquery\.fancybox\.css"
    "jquery\.fancybox-buttons\.css"
    "jquery\.mCustomScrollbar\.min\.css"
    "jquery-ui\.css"
)

# Skip these rel types
SKIP_REL_TYPES=(
    "preconnect"
    "dns-prefetch"
    "pingback"
    "webmention"
    "edituri"
    "wlwmanifest"
    "profile"
)

# Custom HTML attributes to check for URLs
# The script will extract URLs from these attributes and validate them
# Users can add any HTML attribute here that might contain URLs
# Examples: "data-href", "data-url", "ng-href", "formaction", "data-src", etc.
CUSTOM_ATTR_INCLUDES=(
    "data-href"        # Common attribute for storing URLs in JavaScript applications (e.g. in modal windows)
    "data-src"         # Common attribute for storing URLs in JavaScript applications (e.g. in image galleries)
    "data-url"         # Common attribute for storing URLs in JavaScript applications (e.g. in custom widgets)
    "data-link"        # Common attribute for storing URLs in JavaScript applications (e.g. in custom widgets)
    "ng-href"          # Angular framework attribute for defining URLs in HTML templates
    "ng-src"           # Angular framework attribute for defining URLs in HTML templates (e.g. for images)
    "ng-srcset"        # Angular framework attribute for defining URLs in HTML templates (e.g. for responsive images)
    "ng-action"        # Angular framework attribute for defining URLs in HTML templates (e.g. for form actions)
    "ng-include"       # Angular framework attribute for defining URLs in HTML templates (e.g. for including partial views)
    "ng-include-src"   # Angular framework attribute for defining URLs in HTML templates (e.g. for including partial views)
)

# Optimized data structures
declare -A VISITED_URLS
declare -A QUEUED_URLS
declare -A ALL_DISCOVERED
declare -A URL_PARENTS
declare -A URL_STATUS
declare -A ERROR_URLS
declare -A CHECKED_CACHE      # Cache for already checked URLs

# Arrays for final report
declare -a ERROR_URL_LIST=()
declare -a ERROR_TEXT_LIST=()
declare -a ERROR_PARENT_LIST=()
declare -a DYNAMIC_EXCLUDES=()
declare -a REMAINING_ARGS=()
declare -a EXCLUDED_URL_LIST=()  # Track excluded URLs for debug summary
declare -a URL_LOOP_PATTERNS=()  # Track detected URL loop patterns
declare -A URL_LOOP_EXAMPLES=()  # Examples of URLs with loops
declare -a URL_LOOP_ALL_URLS=()  # All URLs where loops were detected

# Counters
TOTAL_URLS=0
ERROR_COUNT=0
EXCLUDED_URLS=0
CHECK_DURATION=0
ERRORS_FOUND=false
YOUTUBE_URLS_CHECKED=0
YOUTUBE_ERRORS=0
CSS_ERRORS_FOUND=false  # Track if any errors were found in CSS files
MAX_URLS_REACHED=false  # Track if MAX_URLS limit was reached
MAX_URLS_CRAWLED_COUNT=0  # Number of URLs crawled when MAX_URLS was reached
MAX_URLS_DISCOVERED_COUNT=0  # Number of URLs discovered when MAX_URLS was reached
URL_LOOPS_DETECTED=false  # Track if URL loops were detected

# Global domain for logging
CURRENT_DOMAIN=""

# Language strings (initialized empty, set by set_language_texts)
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
LANG_DUPLICATE_ERRORS=""
LANG_FALSE_POSITIVES=""
LANG_YOUTUBE_CHECKED=""
LANG_YOUTUBE_UNAVAILABLE=""
LANG_SUCCESS_RATE=""
LANG_COLUMN_URL=""
LANG_COLUMN_ERROR=""
LANG_COLUMN_PARENT=""
LANG_FOOTER_TEXT=""
LANG_CSS_NOTE=""
LANG_PROTECTION_DETECTED=""
LANG_PROTECTION_TITLE=""
LANG_PROTECTION_TEXT=""
LANG_MAX_URLS_SUBJECT=""
LANG_MAX_URLS_TITLE=""
LANG_MAX_URLS_TEXT=""
LANG_URL_LOOP_TITLE=""
LANG_URL_LOOP_TEXT=""
LANG_URL_LOOP_SUBJECT_SUFFIX=""
LANG_URL_LOOP_TABLE_HEADER=""

#==============================================================================
# Basic Functions
#==============================================================================

die() {
    echo "ERROR: $1" >&2
    exit 1
}

log_message() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local domain_prefix=""
    [[ -n "$CURRENT_DOMAIN" ]] && domain_prefix="[$CURRENT_DOMAIN] "
    local message="[$timestamp] ${domain_prefix}INFO: $1"
    echo "$message" >> "$LOG_FILE" 2>/dev/null || true
    [[ "$DEBUG" == "true" ]] && echo "$message" >&2
}

debug_message() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local domain_prefix=""
    [[ -n "$CURRENT_DOMAIN" ]] && domain_prefix="[$CURRENT_DOMAIN] "
    local message="[$timestamp] ${domain_prefix}DEBUG: $1"
    echo "$message" >> "$LOG_FILE" 2>/dev/null || true
    [[ "$DEBUG" == "true" ]] && echo "$message" >&2
}

error_message() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local domain_prefix=""
    [[ -n "$CURRENT_DOMAIN" ]] && domain_prefix="[$CURRENT_DOMAIN] "
    local message="[$timestamp] ${domain_prefix}ERROR: $1"
    echo "$message" >> "$LOG_FILE" 2>/dev/null || true
    echo "$message" >&2
}

#==============================================================================
# Setup Functions
#==============================================================================

show_usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] <base_url> <cms_login_url> <language> <mailto>

REQUIRED PARAMETERS:
  base_url        Base URL to check (e.g., https://www.example.com)
  cms_login_url   CMS login URL or "-" if none
  language        Report language: de (German) or en (English)
  mailto          Email addresses (comma-separated)

COMMAND LINE OPTIONS:
  --exclude REGEX             Add exclude pattern (can use multiple times)
                             Patterns are regex, e.g.: "/api", "\.pdf$", "^/test"
  --max-depth N              Maximum crawl depth (default: 50)
  --max-urls N               Maximum URLs to check (default: 5000)
  --parallel N               Number of parallel workers (default: 20)
  --batch-size N             URLs per batch (default: 50)
  --debug                    Enable debug output
  --send-max-urls-report     Send email notification when MAX_URLS limit is reached
  --max-urls-email EMAIL     Email address for MAX_URLS notifications
  --disable-url-loop-warning Disable URL loop detection warnings in reports
  --exclude-protected-pages  Exclude protected pages from error reports
  -h, --help                 Show this help

ENVIRONMENT VARIABLES (optional):
  Core Settings:
    LOG_FILE                    Log file path (default: /var/log/linkchecker.log)
    DEBUG                       Enable debug mode: true/false (default: false)
    PARALLEL_WORKERS            Number of parallel URL checks (default: 20)
    BATCH_SIZE                  URLs to process per batch (default: 50)
    CONNECTION_CACHE_SIZE       Curl connection cache size (default: 10000)
  
  URL Configuration:
    MAX_DEPTH                   Maximum crawl depth (default: 50)
    MAX_URLS                    Maximum URLs to check (default: 5000)
    MAX_URL_LENGTH              Maximum URL length to process (default: 2000)
    REQUEST_DELAY               Delay between requests in seconds (default: 0)
    CHECK_METHOD                Initial check method: HEAD or GET (default: HEAD)
  
  URL Loop Detection:
    URL_LOOP_THRESHOLD          Repetitions to consider as loop (default: 2)
    URL_LOOP_MIN_SEGMENTS       Minimum URL segments to check for loops (default: 2)
    URL_LOOP_ENABLE_WARNING     Enable URL loop warnings: true/false (default: true)
  
  Error Handling:
    INCLUDE_PROTECTED_IN_REPORT Include protected pages: true/false (default: true)
    REDIRECT_CSS_ERRORS_TO_ADMIN Redirect CSS error reports: true/false (default: true)
    CSS_ERROR_ADMIN_EMAIL       Admin email for CSS errors
    SEND_REPORT_ON_MAX_URLS_REACHED Send MAX_URLS notification: true/false (default: true)
    MAX_URLS_ADMIN_EMAIL        Email for MAX_URLS notifications
  
  External Services:
    YOUTUBE_MAX_RETRIES         Max retry attempts for YouTube (default: 3)
    CURL_IMPERSONATE_BINARY     Path to curl-impersonate (default: ./curl/curl-impersonate-chrome)
    CURL_TIMEOUT                Connection timeout seconds (default: 15)
    CURL_MAX_REDIRECTS          Maximum redirects to follow (default: 10)
  
  Email & Branding:
    MAIL_SENDER                 Email sender address
    MAIL_SENDER_NAME            Email sender name
    SENDMAIL_BINARY             Path to sendmail (default: /usr/sbin/sendmail)
    LOGO_URL                    Logo URL for reports
    LOGO_ALT                    Logo alt text
    THEME_COLOR                 Theme color for reports (default: #832883)

NOTE: 
  - Options support '=' syntax (e.g., --exclude=REGEX, --max-depth=5)
  - Environment variables override defaults but are overridden by command line options
  - Requires curl-impersonate binary to bypass bot protection

EXAMPLES:
  Basic usage:
    $(basename "$0") https://example.com - de admin@example.com
  
  With exclusions and debug:
    $(basename "$0") https://example.com - en admin@example.com \\
      --debug --exclude "/api" --exclude "\.pdf$"
  
  With limits and parallel control:
    $(basename "$0") https://example.com - en admin@example.com \\
      --max-urls=1000 --parallel=10 --batch-size=25
  
  Using environment variables:
    DEBUG=true MAX_URLS=1000 REQUEST_DELAY=1 \\
      $(basename "$0") https://example.com - en admin@example.com
EOF
}

set_language_texts() {
    local lang="$1"
    
    # Convert language to uppercase for variable prefix
    local lang_prefix="DE"  # Default to German
    [[ "$lang" == "en" ]] && lang_prefix="EN"
    
    # List of all language variables to set
    local vars=("SUBJECT" "INTRO_TITLE" "INTRO_TEXT" "CMS_TITLE" "CMS_TEXT"
                "SUMMARY_TITLE" "DETAILS_TITLE" "DURATION" "TOTAL_URLS" "ERROR_URLS"
                "DUPLICATE_ERRORS" "FALSE_POSITIVES" "YOUTUBE_CHECKED" "YOUTUBE_UNAVAILABLE"
                "SUCCESS_RATE" "COLUMN_URL" "COLUMN_ERROR" "COLUMN_PARENT" "FOOTER_TEXT" "CSS_NOTE"
                "PROTECTION_DETECTED" "PROTECTION_TITLE" "PROTECTION_TEXT"
                "MAX_URLS_SUBJECT" "MAX_URLS_TITLE" "MAX_URLS_TEXT"
                "URL_LOOP_TITLE" "URL_LOOP_TEXT" "URL_LOOP_SUBJECT_SUFFIX" "URL_LOOP_TABLE_HEADER")
    
    # Dynamically set language variables
    for var in "${vars[@]}"; do
        local source_var="LANG_${lang_prefix}_${var}"
        local target_var="LANG_${var}"
        eval "${target_var}=\"\${${source_var}}\""
    done
}

replace_placeholders() {
    local text="$1"
    local base_url="$2"
    local cms_url="$3"
    
    # Replace placeholders with actual values
    text="${text//###base_url###/$base_url}"
    text="${text//###cms_url###/$cms_url}"
    
    echo "$text"
}

parse_arguments() {
    REMAINING_ARGS=()
    while [[ $# -gt 0 ]]; do
        case $1 in
            --exclude)
                # Handle --exclude pattern (with space)
                shift
                if [[ -n "$1" ]] && [[ ! "$1" =~ ^-- ]]; then
                    DYNAMIC_EXCLUDES+=("$1")
                    shift
                else
                    die "Missing value for --exclude parameter"
                fi
                ;;
            --exclude=*)
                DYNAMIC_EXCLUDES+=("${1#*=}")
                shift
                ;;
            --max-depth)
                # Handle --max-depth N (with space)
                shift
                if [[ -n "$1" ]] && [[ ! "$1" =~ ^-- ]]; then
                    MAX_DEPTH="$1"
                    shift
                else
                    die "Missing value for --max-depth parameter"
                fi
                ;;
            --max-depth=*)
                MAX_DEPTH="${1#*=}"
                shift
                ;;
            --max-urls)
                # Handle --max-urls N (with space)
                shift
                if [[ -n "$1" ]] && [[ ! "$1" =~ ^-- ]]; then
                    MAX_URLS="$1"
                    shift
                else
                    die "Missing value for --max-urls parameter"
                fi
                ;;
            --max-urls=*)
                MAX_URLS="${1#*=}"
                shift
                ;;
            --parallel)
                # Handle --parallel N (with space)
                shift
                if [[ -n "$1" ]] && [[ ! "$1" =~ ^-- ]]; then
                    PARALLEL_WORKERS="$1"
                    shift
                else
                    die "Missing value for --parallel parameter"
                fi
                ;;
            --parallel=*)
                PARALLEL_WORKERS="${1#*=}"
                shift
                ;;
            --batch-size)
                # Handle --batch-size N (with space)
                shift
                if [[ -n "$1" ]] && [[ ! "$1" =~ ^-- ]]; then
                    BATCH_SIZE="$1"
                    shift
                else
                    die "Missing value for --batch-size parameter"
                fi
                ;;
            --batch-size=*)
                BATCH_SIZE="${1#*=}"
                shift
                ;;
            --send-max-urls-report)
                SEND_REPORT_ON_MAX_URLS_REACHED="true"
                shift
                ;;
            --max-urls-email)
                # Handle --max-urls-email EMAIL (with space)
                shift
                if [[ -n "$1" ]] && [[ ! "$1" =~ ^-- ]]; then
                    MAX_URLS_ADMIN_EMAIL="$1"
                    shift
                else
                    die "Missing value for --max-urls-email parameter"
                fi
                ;;
            --max-urls-email=*)
                MAX_URLS_ADMIN_EMAIL="${1#*=}"
                shift
                ;;
            --disable-url-loop-warning)
                URL_LOOP_ENABLE_WARNING="false"
                shift
                ;;
            --exclude-protected-pages)
                INCLUDE_PROTECTED_IN_REPORT="false"
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
            *)
                REMAINING_ARGS+=("$1")
                shift
                ;;
        esac
    done
}

validate_parameters() {
    local base_url="$1"
    local cms_login_url="$2"
    local language="$3"
    local mailto="$4"
    
    [[ "$base_url" =~ ^https?:// ]] || die "Invalid base URL"
    [[ "$cms_login_url" == "-" || "$cms_login_url" =~ ^https?:// ]] || die "Invalid CMS URL"
    [[ "$language" =~ ^(de|en)$ ]] || die "Language must be de or en"
    [[ "$mailto" =~ @ ]] || die "Invalid email"
}

check_prerequisites() {
    [[ -x "$CURL_IMPERSONATE_BINARY" ]] || die "curl-impersonate not found at $CURL_IMPERSONATE_BINARY"
    [[ -x "$SENDMAIL_BINARY" ]] || die "sendmail not found at $SENDMAIL_BINARY"
    command -v xargs &>/dev/null || die "xargs command not found"
    
    # Check log file permissions
    if ! touch "$LOG_FILE" 2>/dev/null; then
        echo "ERROR: Cannot write to log file $LOG_FILE" >&2
        echo "" >&2
        echo "Please run the following commands to fix this:" >&2
        echo "" >&2
        echo "  sudo touch $LOG_FILE" >&2
        echo "  sudo chmod 666 $LOG_FILE" >&2
        echo "" >&2
        echo "Or to give write access only to your user:" >&2
        echo "" >&2
        echo "  sudo touch $LOG_FILE" >&2
        echo "  sudo chown $(whoami):$(whoami) $LOG_FILE" >&2
        echo "" >&2
        exit 1
    fi
    
    debug_message "Prerequisites OK"
}

#==============================================================================
# URL Functions
#==============================================================================

normalize_url() {
    local url="$1"
    local base_url="$2"
    
    [[ -z "$url" ]] && return
    
    # Remove fragment
    url="${url%%#*}"
    # Trim spaces
    url="${url// /%20}"
    
    # Skip non-http
    if [[ "$url" =~ ^[a-zA-Z]+: ]] && [[ ! "$url" =~ ^https?:// ]]; then
        return
    fi
    
    # Handle different URL types
    if [[ "$url" =~ ^https?:// ]]; then
        echo "$url"
    elif [[ "$url" =~ ^// ]]; then
        echo "${base_url%%://*}:${url}"
    elif [[ "$url" =~ ^/ ]]; then
        local domain="${base_url%%://*}://${base_url#*://}"
        domain="${domain%%/*}"
        echo "${domain}${url}"
    else
        local base="${base_url%/*}"
        [[ "$base_url" =~ /$ ]] && base="$base_url"
        echo "${base%/}/${url}"
    fi
}

is_url_excluded() {
    local url="$1"
    for pattern in "${EXCLUDES[@]}" "${DYNAMIC_EXCLUDES[@]}"; do
        # Use grep -E for extended regex matching to ensure proper regex interpretation
        if echo "$url" | grep -qE "$pattern"; then
            # Track excluded URL for debug summary (only add once)
            if [[ "$DEBUG" == "true" ]] && [[ ! " ${EXCLUDED_URL_LIST[@]} " =~ " ${url} " ]]; then
                EXCLUDED_URL_LIST+=("$url|$pattern")
            fi
            return 0
        fi
    done
    return 1
}

is_url_in_scope() {
    local url="$1"
    local base_url="$2"
    
    local base_domain="${base_url#*://}"
    base_domain="${base_domain%%/*}"
    
    local url_domain="${url#*://}"
    url_domain="${url_domain%%/*}"
    
    [[ "$url_domain" == "$base_domain" ]]
}

is_url_valid() {
    local url="$1"
    
    # Check URL length
    if [[ ${#url} -gt $MAX_URL_LENGTH ]]; then
        debug_message "URL too long (${#url} chars): ${url:0:100}..."
        return 1
    fi
    
    # Check for obviously malformed URLs
    # Detect repeating patterns like /like/like/like/
    if echo "$url" | grep -qE '(/[^/]+/)\1{5,}'; then
        debug_message "URL has repeating pattern: ${url:0:100}..."
        return 1
    fi
    
    # Check specifically for multiple /like/ patterns (Facebook widget issue)
    if echo "$url" | grep -qE '(/like/){3,}'; then
        debug_message "URL has multiple /like/ patterns: ${url:0:100}..."
        return 1
    fi
    
    # Check for excessive query parameters (possible loop)
    local param_count=$(echo "$url" | grep -o '&' | wc -l)
    if [[ $param_count -gt 50 ]]; then
        debug_message "URL has too many parameters ($param_count): ${url:0:100}..."
        return 1
    fi
    
    return 0
}

#==============================================================================
# Optimized HTML Parsing - Single Pass URL Extraction
#==============================================================================

extract_urls_from_html_optimized() {
    local html_content="$1"
    local base_url="$2"
    
    # Build skip rel types pattern for awk
    local skip_rel_pattern=""
    for rel in "${SKIP_REL_TYPES[@]}"; do
        [[ -n "$skip_rel_pattern" ]] && skip_rel_pattern="${skip_rel_pattern}|"
        skip_rel_pattern="${skip_rel_pattern}${rel}"
    done
    
    # Build custom attribute inclusion pattern for awk
    # This pattern will be used to identify which attributes to extract URLs from
    local include_attr_pattern=""
    for attr in "${CUSTOM_ATTR_INCLUDES[@]}"; do
        [[ -n "$include_attr_pattern" ]] && include_attr_pattern="${include_attr_pattern}|"
        include_attr_pattern="${include_attr_pattern}${attr}"
    done
    
    # Clean binary data and ensure UTF-8 encoding
    # Single pass extraction using awk for better performance
    echo "$html_content" | tr -d '\0' | iconv -f UTF-8 -t UTF-8 -c 2>/dev/null | awk -v base="$base_url" -v skip_rels="$skip_rel_pattern" -v include_attrs="$include_attr_pattern" '
    function normalize(url, base_url,    local_base) {
        # Use local variable to avoid modifying original
        local_base = base_url
        
        # Remove fragment
        gsub(/#.*$/, "", url)
        # Trim spaces
        gsub(/ /, "%20", url)
        
        # Skip non-http
        if (url ~ /^[a-zA-Z]+:/ && url !~ /^https?:\/\//) {
            return ""
        }
        
        # Handle different URL types
        if (url ~ /^https?:\/\//) {
            return url
        } else if (url ~ /^\/\//) {
            split(local_base, parts, "://")
            return parts[1] ":" url
        } else if (url ~ /^\//) {
            split(local_base, parts, "/")
            return parts[1] "//" parts[3] url
        } else {
            # Handle relative URLs
            if (local_base !~ /\/$/) {
                local_base = local_base "/"
            }
            # If base has a file component, remove it
            if (local_base ~ /\/[^\/]+\.[^\/]+$/) {
                sub(/\/[^\/]*$/, "/", local_base)
            }
            return local_base url
        }
    }
    
    {
        # For link tags, check rel attribute
        while (match($0, /<link[^>]*>/, link_tag)) {
            tag = link_tag[0]
            $0 = substr($0, RSTART + RLENGTH)
            
            # Check if this link has a rel attribute we should skip
            if (match(tag, /rel=["\047]([^"\047]*)["\047]/, rel_arr)) {
                rel_value = rel_arr[1]
                if (skip_rels != "" && match(rel_value, skip_rels)) {
                    continue  # Skip this link tag
                }
            }
            
            # Extract href from this link tag
            if (match(tag, /href=["\047]([^"\047]*)["\047]/, href_arr)) {
                url = href_arr[1]
                if (url && url !~ /^(#|mailto:|tel:|javascript:|data:)/) {
                    normalized = normalize(url, base)
                    if (normalized != "" && normalized ~ /^https?:\/\//) {
                        print normalized
                    }
                }
            }
        }
    }
    
    {
        # Extract other URL patterns (non-link tags)
        # Note: Only extract from specific attributes that actually contain URLs
        # Match attributes that are preceded by whitespace or > to avoid matching data-* variants
        while (match($0, /[\s>](src|action|poster)=["\047]([^"\047]*)["\047]/, arr)) {
            url = arr[2]
            if (url && url !~ /^(#|mailto:|tel:|javascript:|data:)/) {
                normalized = normalize(url, base)
                if (normalized != "" && normalized ~ /^https?:\/\//) {
                    print normalized
                }
            }
            $0 = substr($0, RSTART + RLENGTH)
        }
        
        # Extract URLs from custom attributes listed in CUSTOM_ATTR_INCLUDES
        if (include_attrs != "") {
            # Build regex pattern for included attributes
            split(include_attrs, attrs_array, "|")
            for (i in attrs_array) {
                attr = attrs_array[i]
                # Match this specific attribute
                regex = attr "=[\"\\047]([^\"\\047]*)[\"\\047]"
                while (match($0, regex, arr)) {
                    url = arr[1]
                    # Only process if it looks like a URL (starts with / or http)
                    if (url ~ /^(\/|https?:\/\/)/) {
                        normalized = normalize(url, base)
                        if (normalized != "" && normalized ~ /^https?:\/\//) {
                            print normalized
                        }
                    }
                    $0 = substr($0, RSTART + RLENGTH)
                }
            }
        }
        
        # Extract href from non-link tags (a, area, etc)
        while (match($0, /<(a|area)[^>]*href=["\047]([^"\047]*)["\047]/, arr)) {
            url = arr[2]
            if (url && url !~ /^(#|mailto:|tel:|javascript:|data:)/) {
                normalized = normalize(url, base)
                if (normalized != "" && normalized ~ /^https?:\/\//) {
                    print normalized
                }
            }
            $0 = substr($0, RSTART + RLENGTH)
        }
        
        # Extract srcset URLs
        if (match($0, /srcset=["\047]([^"\047]*)["\047]/, arr)) {
            split(arr[1], urls, ",")
            for (i in urls) {
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", urls[i])
                split(urls[i], parts, " ")
                url = parts[1]
                if (url && url !~ /^(#|mailto:|tel:|javascript:|data:)/) {
                    normalized = normalize(url, base)
                    if (normalized != "" && normalized ~ /^https?:\/\//) {
                        print normalized
                    }
                }
            }
        }
    }' | sort -u | while IFS= read -r url; do
        # Post-process to filter out bad URLs
        if is_url_valid "$url"; then
            echo "$url"
        fi
    done
}

extract_urls_from_css() {
    local css_content="$1"
    local css_url="$2"
    
    # Optimized CSS URL extraction
    echo "$css_content" | grep -oE 'url\([^)]+\)' | sed 's/url(//; s/)//; s/["'"'"']//g' | while IFS= read -r url; do
        [[ -z "$url" || "$url" =~ ^data: ]] && continue
        local normalized=$(normalize_url "$url" "$css_url")
        [[ -n "$normalized" ]] && [[ "$normalized" =~ ^https?:// ]] && is_url_valid "$normalized" && echo "$normalized"
    done
}

#==============================================================================
# Optimized HTTP Functions with Connection Pooling
#==============================================================================

create_curl_config() {
    cat <<EOF
--ciphers TLS_AES_128_GCM_SHA256,TLS_AES_256_GCM_SHA384,TLS_CHACHA20_POLY1305_SHA256,ECDHE-ECDSA-AES128-GCM-SHA256,ECDHE-RSA-AES128-GCM-SHA256,ECDHE-ECDSA-AES256-GCM-SHA384,ECDHE-RSA-AES256-GCM-SHA384,ECDHE-ECDSA-CHACHA20-POLY1305,ECDHE-RSA-CHACHA20-POLY1305,ECDHE-RSA-AES128-SHA,ECDHE-RSA-AES256-SHA,AES128-GCM-SHA256,AES256-GCM-SHA384,AES128-SHA,AES256-SHA
-H "sec-ch-ua: \"Chromium\";v=\"116\", \"Not)A;Brand\";v=\"24\", \"Google Chrome\";v=\"116\""
-H "sec-ch-ua-mobile: ?0"
-H "sec-ch-ua-platform: \"Windows\""
-H "Upgrade-Insecure-Requests: 1"
-H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Safari/537.36"
-H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7"
-H "Sec-Fetch-Site: none"
-H "Sec-Fetch-Mode: navigate"
-H "Sec-Fetch-User: ?1"
-H "Sec-Fetch-Dest: document"
-H "Accept-Encoding: gzip, deflate, br"
-H "Accept-Language: en-US,en;q=0.9"
--cert-compression brotli
--http2
--http2-no-server-push
--compressed
--tlsv1.2
--alps
--tls-permute-extensions
--cert-compression brotli
--location
--max-redirs $CURL_MAX_REDIRECTS
--connect-timeout $CURL_TIMEOUT
--max-time $((CURL_TIMEOUT * 2))
-s
EOF
}

http_request_pooled() {
    local url="$1"
    local method="${2:-GET}"
    
    # Create temporary config file for connection pooling
    local config_file="/tmp/curl_config_$$"
    create_curl_config > "$config_file"
    
    # Execute curl with connection cache
    local full_response
    full_response=$("$CURL_IMPERSONATE_BINARY" \
        --config "$config_file" \
        --parallel \
        --parallel-max "$CONNECTION_CACHE_SIZE" \
        $([ "$method" == "HEAD" ] && echo "--head") \
        -w "\n__STATUS_CODE__%{http_code}" \
        -- "$url" 2>/dev/null | tr -d '\0') || echo "__STATUS_CODE__000"
    
    rm -f "$config_file"
    
    # Extract status code and content
    local status_code="${full_response##*__STATUS_CODE__}"
    local content="${full_response%__STATUS_CODE__*}"
    
    echo "$status_code"
    [[ -n "$content" ]] && echo "$content"
}

#==============================================================================
# Parallel URL Checking
#==============================================================================

check_url_worker() {
    local url="$1"
    local parent="$2"
    local base_url="$3"
    
    # First validate URL
    if ! is_url_valid "$url"; then
        echo "SKIP|$url|Invalid URL|$parent"
        return
    fi
    
    # Determine if URL is external (different domain)
    local is_external=false
    
    # Only check if URL is absolute (starts with http:// or https://)
    if [[ "$url" =~ ^https?:// ]]; then
        local base_domain="${base_url#*://}"
        base_domain="${base_domain%%/*}"
        local url_domain="${url#*://}"
        url_domain="${url_domain%%/*}"
        [[ "$url_domain" != "$base_domain" ]] && is_external=true
    fi
    
    # Determine method: GET for external, HEAD first for internal
    local method="HEAD"
    if [[ "$is_external" == "true" ]]; then
        method="GET"
        debug_message "External URL detected, using GET method for $url"
    else
        debug_message "Internal URL detected, trying HEAD first for $url"
    fi
    
    # Make the request
    local response=$(http_request_pooled "$url" "$method" 2>/dev/null)
    local status=$(echo "$response" | head -n1)
    local body=""
    
    # For internal URLs: if HEAD fails with 4xx or 5xx, retry with GET
    if [[ "$is_external" == "false" ]] && [[ "$method" == "HEAD" ]] && [[ -n "$status" ]] && [[ "$status" -ge 400 ]]; then
        debug_message "HEAD request returned $status for $url, retrying with GET"
        response=$(http_request_pooled "$url" "GET" 2>/dev/null)
        status=$(echo "$response" | head -n1)
        method="GET"
    fi
    
    # Get body if we used GET or need it for error analysis
    if [[ "$method" == "GET" ]]; then
        body=$(echo "$response" | tail -n +2)
    fi
    
    # Check if this is a Cloudflare challenge page
    local is_protected=false
    local error_suffix=""
    if [[ "$status" == "403" ]] && [[ -n "$body" ]]; then
        if echo "$body" | grep -qE "(cf-challenge|cf_chl_opt|Cloudflare|Just a moment|Enable JavaScript and cookies to continue)"; then
            debug_message "Cloudflare challenge detected for $url"
            is_protected=true
            error_suffix=" ${LANG_PROTECTION_DETECTED}"
        fi
    fi
    
    # Determine result
    if [[ -z "$status" ]] || [[ "$status" -ge 400 ]]; then
        if [[ "$is_protected" == "true" ]]; then
            echo "PROTECTED_ERROR|$url|HTTP ${status:-Failed}${error_suffix}|$parent"
        else
            echo "ERROR|$url|HTTP ${status:-Failed}|$parent"
        fi
    else
        echo "OK|$url|$status|$parent"
    fi
}

export -f check_url_worker http_request_pooled create_curl_config normalize_url debug_message is_url_valid is_url_in_scope
export CURL_IMPERSONATE_BINARY CURL_TIMEOUT CURL_MAX_REDIRECTS CHECK_METHOD CONNECTION_CACHE_SIZE DEBUG LOG_FILE CURRENT_DOMAIN INCLUDE_PROTECTED_IN_REPORT LANG_PROTECTION_DETECTED MAX_URL_LENGTH CSS_ERRORS_FOUND REDIRECT_CSS_ERRORS_TO_ADMIN YOUTUBE_MAX_RETRIES URL_LOOP_THRESHOLD URL_LOOP_MIN_SEGMENTS

check_urls_parallel() {
    local base_url="$1"
    local -a urls_to_check=()
    local -A seen_urls=()
    
    # Build list of URLs to check (with deduplication and validation)
    for url in "${!ALL_DISCOVERED[@]}"; do
        # Apply MAX_URLS limit if set
        if [[ "$MAX_URLS" -ne -1 ]] && [[ ${#urls_to_check[@]} -ge "$MAX_URLS" ]]; then
            debug_message "Reached MAX_URLS limit ($MAX_URLS), stopping URL collection"
            MAX_URLS_REACHED=true
            if [[ "$MAX_URLS_CRAWLED_COUNT" -eq 0 ]]; then
                # If not set during crawling, set it here during checking
                MAX_URLS_CRAWLED_COUNT="${#urls_to_check[@]}"
                MAX_URLS_DISCOVERED_COUNT="${#ALL_DISCOVERED[@]}"
            fi
            break
        fi
        
        # Validate URL before checking
        if ! is_url_valid "$url"; then
            debug_message "Skipping invalid URL: ${url:0:100}..."
            ((EXCLUDED_URLS++))
            continue
        fi
        
        if [[ -z "${seen_urls[$url]:-}" ]] && ! is_url_excluded "$url"; then
            urls_to_check+=("$url")
            seen_urls["$url"]=1
        elif is_url_excluded "$url"; then
            ((EXCLUDED_URLS++))
        fi
    done
    
    log_message "Checking ${#urls_to_check[@]} URLs with $PARALLEL_WORKERS parallel workers"
    
    local checked=0
    local batch_num=0
    local protected_count=0
    
    # Use temporary file to avoid subshell issues
    local temp_results="/tmp/linkchecker_results_$$"
    > "$temp_results"
    
    # Process in batches for better progress reporting
    while [[ $checked -lt ${#urls_to_check[@]} ]]; do
        ((batch_num++))
        local batch_end=$((checked + BATCH_SIZE))
        [[ $batch_end -gt ${#urls_to_check[@]} ]] && batch_end=${#urls_to_check[@]}
        
        log_message "Processing batch $batch_num: URLs $((checked + 1)) to $batch_end"
        
        # Process batch in parallel - prepare URLs with parent info
        local batch_data=()
        for ((i=checked; i<batch_end && i<${#urls_to_check[@]}; i++)); do
            local url="${urls_to_check[$i]}"
            local parent="${URL_PARENTS[$url]:-}"
            batch_data+=("${url}|${parent}|${base_url}")
        done
        
        # Write results to temp file to avoid subshell issues
        printf "%s\n" "${batch_data[@]}" | \
        xargs -P "$PARALLEL_WORKERS" -I {} bash -c '
            IFS="|" read -r url parent base_url <<< "$1"
            check_url_worker "$url" "$parent" "$base_url"
        ' _ "{}" >> "$temp_results"
        
        checked=$batch_end
    done
    
    # Process results from temp file (no subshell)
    while IFS='|' read -r result url status parent; do
        ((TOTAL_URLS++))
        
        case "$result" in
            ERROR)
                ERROR_URL_LIST+=("$url")
                ERROR_TEXT_LIST+=("$status")
                ERROR_PARENT_LIST+=("$parent")
                ((ERROR_COUNT++))
                ERRORS_FOUND=true
                
                # Check if the error is from a CSS file
                if [[ "$parent" =~ \.css(\?.*)?$ ]]; then
                    CSS_ERRORS_FOUND=true
                    debug_message "CSS error detected: $url found in $parent"
                fi
                ;;
            PROTECTED_ERROR)
                ((protected_count++))
                # Only add to error list if including protected pages
                if [[ "$INCLUDE_PROTECTED_IN_REPORT" == "true" ]]; then
                    ERROR_URL_LIST+=("$url")
                    ERROR_TEXT_LIST+=("$status")
                    ERROR_PARENT_LIST+=("$parent")
                    ((ERROR_COUNT++))
                    ERRORS_FOUND=true
                    
                    # Check if the error is from a CSS file
                    if [[ "$parent" =~ \.css(\?.*)?$ ]]; then
                        CSS_ERRORS_FOUND=true
                        debug_message "CSS error detected: $url found in $parent"
                    fi
                else
                    debug_message "Excluding protected page from report: $url"
                fi
                ;;
            OK|CACHED)
                URL_STATUS["$url"]="$status"
                ;;
            SKIP)
                debug_message "Skipped invalid URL: ${url:0:100}..."
                ;;
        esac
        
        # Real-time progress
        if [[ $((TOTAL_URLS % 10)) -eq 0 ]]; then
            debug_message "Progress: $TOTAL_URLS URLs checked, $ERROR_COUNT errors found"
        fi
    done < "$temp_results"
    
    # Cleanup
    rm -f "$temp_results"
    
    if [[ $protected_count -gt 0 ]]; then
        log_message "Found $protected_count protected pages"
    fi
    
    log_message "Check complete: $TOTAL_URLS checked, $ERROR_COUNT errors"
}

#==============================================================================
# URL Loop Detection
#==============================================================================

detect_url_loops() {
    local base_url="$1"
    
    debug_message "Checking for URL loop patterns"
    
    local loop_count=0
    # Global patterns tracking - only for actual loops found
    declare -A global_patterns
    declare -A global_pattern_examples
    
    for url in "${!ALL_DISCOVERED[@]}"; do
        # Skip external URLs
        is_url_in_scope "$url" "$base_url" || continue
        
        # Skip excluded URLs - respect both global and dynamic exclusions
        if is_url_excluded "$url"; then
            debug_message "Skipping excluded URL from loop detection: $url"
            continue
        fi
        
        # Remove domain and query parameters for analysis
        local path="${url#*://}"
        path="${path#*/}"
        path="${path%%\?*}"
        path="${path%%#*}"
        
        # Skip if path is too short
        [[ -z "$path" ]] && continue
        
        # Split path into segments
        IFS='/' read -ra segments <<< "$path"
        
        # Skip if not enough segments to check
        [[ ${#segments[@]} -lt $URL_LOOP_MIN_SEGMENTS ]] && continue
        
        # Track if THIS SPECIFIC URL has a loop pattern
        local url_has_loop=false
        
        # Method 1: Check for CONSECUTIVE repetitions of the same segment
        # Examples that SHOULD be flagged:
        #   /products/products/ (same segment repeated consecutively)
        #   /home/home/home/ (same segment repeated 3x consecutively)
        #   /api/v1/v1/endpoint (v1 repeated consecutively)
        # Examples that should NOT be flagged:
        #   /cpt-angebote-re/4305/ (different segments)
        #   /products/category/products/ (products appears twice but not consecutively)
        local prev_segment=""
        local repetition_count=1
        local max_repetition=1
        
        for segment in "${segments[@]}"; do
            if [[ "$segment" == "$prev_segment" ]] && [[ -n "$segment" ]]; then
                ((repetition_count++))
                [[ $repetition_count -gt $max_repetition ]] && max_repetition=$repetition_count
            else
                repetition_count=1
            fi
            prev_segment="$segment"
        done
        
        if [[ $max_repetition -ge $URL_LOOP_THRESHOLD ]]; then
            url_has_loop=true
            debug_message "Method 1: Found consecutive repetition in $url (${max_repetition}x)"
        fi
        
        # Method 2: Check for REPEATING PATTERNS of 2+ segments
        # Examples that SHOULD be flagged:
        #   /about/services/about/services/ (pattern "about/services" repeats)
        #   /api/v1/users/api/v1/users/ (pattern "api/v1/users" repeats)
        #   /a/b/a/b/a/b/ (pattern "a/b" repeats 3 times)
        # Examples that should NOT be flagged:
        #   /cpt-angebote-re/4305/ (no repeating multi-segment pattern)
        #   /products/category/items/ (no pattern repetition)
        local pattern_found=false
        if [[ ${#segments[@]} -ge 4 ]]; then  # Need at least 4 segments for 2x repetition of 2-segment pattern
            for ((i=0; i<=((${#segments[@]}-4)); i++)); do
                # Try 2-segment patterns
                if [[ $((i+3)) -lt ${#segments[@]} ]]; then
                    local pattern="${segments[$i]}/${segments[$i+1]}"
                    local pattern_repeat_count=1
                    
                    # Check if pattern repeats immediately after
                    for ((j=i+2; j<${#segments[@]}-1; j+=2)); do
                    if [[ "${segments[$j]}/${segments[$j+1]}" == "$pattern" ]]; then
                        ((pattern_repeat_count++))
                    else
                        break
                    fi
                done
                
                    if [[ $pattern_repeat_count -ge $URL_LOOP_THRESHOLD ]]; then
                        pattern_found=true
                        url_has_loop=true
                        debug_message "Method 2: Found repeating pattern '$pattern' (${pattern_repeat_count}x) in $url"
                        
                        # Store in global patterns only if it's a real loop
                        if [[ -z "${global_patterns[$pattern]}" ]]; then
                            global_patterns["$pattern"]=1
                            global_pattern_examples["$pattern"]="$url"
                        fi
                        break
                    fi
                fi
            done
        fi
        
        # Method 3: Check for SAME SEGMENT appearing multiple times at REGULAR intervals
        # Examples that SHOULD be flagged:
        #   /api/users/api/posts/api/comments/ (api appears every 2 segments)
        #   /v1/data/v1/users/v1/posts/ (v1 appears at regular intervals)
        # Examples that should NOT be flagged:
        #   /cpt-angebote-re/an-ruhiger-lage/ (segments appear only once)
        #   /home/products/services/home/ (home appears twice but not at regular intervals)
        # IMPORTANT: Clear arrays for EACH URL to avoid cross-contamination
        unset segment_counts segment_positions
        declare -A segment_counts=()
        declare -A segment_positions=()
        
        for i in "${!segments[@]}"; do
            local segment="${segments[$i]}"
            if [[ -n "$segment" ]]; then
                if [[ -v segment_counts["$segment"] ]]; then
                    segment_counts["$segment"]=$((segment_counts["$segment"] + 1))
                else
                    segment_counts["$segment"]=1
                fi
                segment_positions["$segment"]+="$i "
            fi
        done
        
        for segment in "${!segment_counts[@]}"; do
            # Only check segments that appear multiple times
            if [[ ${segment_counts[$segment]} -ge $URL_LOOP_THRESHOLD ]]; then
                local positions=(${segment_positions[$segment]})
                local is_suspicious=false
                
                # Check for REGULAR intervals (suggesting automated/looping generation)
                if [[ ${#positions[@]} -ge $URL_LOOP_THRESHOLD ]]; then
                    # Calculate intervals between appearances
                    local first_interval=$((positions[1] - positions[0]))
                    local has_regular_pattern=true
                    
                    # Check if all intervals are the same AND small (<=3)
                    for ((i=2; i<${#positions[@]}; i++)); do
                        local curr_interval=$((positions[i] - positions[i-1]))
                        # Intervals must be consistent AND reasonably small to be suspicious
                        if [[ $curr_interval -ne $first_interval ]] || [[ $first_interval -gt 3 ]]; then
                            has_regular_pattern=false
                            break
                        fi
                    done
                    
                    # Only flag if intervals are regular AND small (indicating a loop pattern)
                    if [[ "$has_regular_pattern" == "true" ]] && [[ $first_interval -le 3 ]] && [[ $first_interval -gt 0 ]]; then
                        is_suspicious=true
                        url_has_loop=true
                        debug_message "Method 3: Found suspicious regular repetition of '$segment' every $first_interval segments in $url"
                    fi
                fi
            fi
        done
        
        # Only add this URL to the loop list if it actually has a loop pattern
        if [[ "$url_has_loop" == "true" ]]; then
            ((loop_count++))
            URL_LOOP_ALL_URLS+=("$url")
        fi
    done
    
    # Set global detection flag based on actual loops found
    if [[ $loop_count -gt 0 ]]; then
        URL_LOOPS_DETECTED=true
        log_message "Detected URL loops: $loop_count URLs with repetitive patterns"
        
        # Store global patterns if any were found
        if [[ ${#global_patterns[@]} -gt 0 ]]; then
            for pattern in "${!global_patterns[@]}"; do
                URL_LOOP_PATTERNS+=("$pattern")
                URL_LOOP_EXAMPLES["$pattern"]="${global_pattern_examples[$pattern]}"
            done
        fi
    else
        debug_message "No URL loop patterns detected"
    fi
}

#==============================================================================
# Optimized Crawling with Better Queue Management
#==============================================================================

crawl_website() {
    local base_url="$1"
    local max_depth="$2"
    
    # Extract domain for progress messages
    local domain="${base_url#*://}"
    domain="${domain%%/*}"
    
    log_message "Starting crawl: $base_url"
    
    # Use a more efficient queue implementation
    local queue_file="/tmp/crawl_queue_$$"
    local visited_file="/tmp/crawl_visited_$$"
    
    echo "$base_url|0|$base_url" > "$queue_file"
    touch "$visited_file"
    
    local crawled=0
    local discovered_count=0
    
    while [[ -s "$queue_file" ]]; do
        # Check if we've reached the MAX_URLS limit before processing next URL
        if [[ "$MAX_URLS" -ne -1 && "$crawled" -ge "$MAX_URLS" ]]; then
            log_message "Reached MAX_URLS limit ($MAX_URLS), stopping crawl"
            MAX_URLS_REACHED=true
            MAX_URLS_CRAWLED_COUNT="$crawled"
            MAX_URLS_DISCOVERED_COUNT="${#ALL_DISCOVERED[@]}"
            break
        fi
        
        # Get next URL from queue
        IFS='|' read -r url depth parent < "$queue_file"
        tail -n +2 "$queue_file" > "$queue_file.tmp" && mv "$queue_file.tmp" "$queue_file"
        
        # Skip if already visited
        grep -qF "$url" "$visited_file" && continue
        echo "$url" >> "$visited_file"
        
        # Track in memory structures
        VISITED_URLS["$url"]=1
        ALL_DISCOVERED["$url"]=1
        URL_PARENTS["$url"]="$parent"
        ((crawled++))
        
        # Progress
        [[ $((crawled % 10)) -eq 0 ]] && log_message "Progress: Crawled $crawled pages, discovered ${#ALL_DISCOVERED[@]} URLs"
        
        # Check depth limit
        [[ "$max_depth" -ne -1 && "$depth" -ge "$max_depth" ]] && continue
        
        # Only crawl internal URLs
        is_url_in_scope "$url" "$base_url" || continue
        
        # Skip JS files
        [[ "$url" =~ \.js(\?.*)?$ ]] && continue
        
        # Get new URLs from page
        local response=$(http_request_pooled "$url" "$CRAWL_METHOD")
        local status=$(echo "$response" | head -n1)
        local content=$(echo "$response" | tail -n +2)
        
        if [[ "$status" =~ ^2[0-9][0-9]$ ]] && [[ -n "$content" ]]; then
            # Check if content is HTML before parsing
            if echo "$content" | head -c 1000 | grep -qiE '<(html|head|body|div|a|link|script|meta)'; then
                local new_urls=$(extract_urls_from_html_optimized "$content" "$url")
            
            while IFS= read -r new_url; do
                [[ -z "$new_url" ]] && continue
                
                # Validate URL before adding
                if ! is_url_valid "$new_url"; then
                    debug_message "Skipping invalid discovered URL: ${new_url:0:100}..."
                    EXCLUDED_URLS=$((EXCLUDED_URLS + 1))
                    continue
                fi
                
                # Skip if excluded
                is_url_excluded "$new_url" && { EXCLUDED_URLS=$((EXCLUDED_URLS + 1)); continue; }
                
                # Add to discovered set
                if [[ -z "${ALL_DISCOVERED[$new_url]}" ]]; then
                    ALL_DISCOVERED["$new_url"]=1
                    URL_PARENTS["$new_url"]="$url"
                    ((discovered_count++))
                    
                    # Queue for crawling if internal and not visited - WITH VALIDATION
                    if is_url_in_scope "$new_url" "$base_url" && \
                       ! grep -qF "$new_url" "$visited_file" && \
                       ! [[ "$new_url" =~ \.js(\?.*)?$ ]] && \
                       is_url_valid "$new_url"; then
                        echo "$new_url|$((depth + 1))|$url" >> "$queue_file"
                    fi
                fi
            done <<< "$new_urls"
            fi
        fi
        
        [[ "$REQUEST_DELAY" != "0" ]] && sleep "$REQUEST_DELAY"
    done
    
    # Cleanup
    rm -f "$queue_file" "$visited_file"
    
    log_message "Crawl complete: Crawled $crawled pages, discovered ${#ALL_DISCOVERED[@]} URLs"
    
    # Process CSS files
    process_css_files "$base_url"
}

process_css_files() {
    local base_url="$1"
    local css_count=0
    local css_urls_found=0
    
    for url in "${!ALL_DISCOVERED[@]}"; do
        if [[ "$url" =~ \.css(\?.*)?$ ]]; then
            ((css_count++))
            debug_message "Processing CSS: $url"
            
            local css_response=$(http_request_pooled "$url" "GET")
            local css_status=$(echo "$css_response" | head -n1)
            
            if [[ "$css_status" =~ ^2[0-9][0-9]$ ]]; then
                local css_content=$(echo "$css_response" | tail -n +2)
                local css_urls=$(extract_urls_from_css "$css_content" "$url")
                
                while IFS= read -r css_url; do
                    if [[ -n "$css_url" ]] && [[ -z "${ALL_DISCOVERED[$css_url]}" ]]; then
                        ALL_DISCOVERED["$css_url"]=1
                        URL_PARENTS["$css_url"]="$url"
                        ((css_urls_found++))
                    fi
                done <<< "$css_urls"
            fi
        fi
    done
    
    [[ $css_count -gt 0 ]] && log_message "Processed $css_count CSS files, found $css_urls_found additional URLs"
}

#==============================================================================
# Parallel YouTube Checking
#==============================================================================

check_youtube_videos_parallel() {
    log_message "Checking YouTube videos"
    
    local -a youtube_urls=()
    declare -A video_ids
    
    # Collect unique YouTube video IDs
    for url in "${!ALL_DISCOVERED[@]}"; do
        echo "$url" | grep -qE "$YOUTUBE_DOMAINS" || continue
        
        local video_id=""
        if [[ "$url" =~ youtu\.be/([a-zA-Z0-9_-]+) ]]; then
            video_id="${BASH_REMATCH[1]}"
        elif [[ "$url" =~ [\?\&]v=([a-zA-Z0-9_-]+) ]]; then
            video_id="${BASH_REMATCH[1]}"
        elif [[ "$url" =~ /embed/([a-zA-Z0-9_-]+) ]]; then
            video_id="${BASH_REMATCH[1]}"
        fi
        
        if [[ -n "$video_id" ]] && [[ -z "${video_ids[$video_id]}" ]]; then
            video_ids["$video_id"]="$url"
            youtube_urls+=("$video_id|$url")
        fi
    done
    
    [[ ${#youtube_urls[@]} -eq 0 ]] && return
    
    log_message "Checking ${#youtube_urls[@]} YouTube videos"
    
    # Use temporary file to avoid subshell issues
    local temp_youtube_results="/tmp/linkchecker_youtube_$$"
    > "$temp_youtube_results"
    
    # Check YouTube videos in parallel (with rate limiting and retry logic)
    printf "%s\n" "${youtube_urls[@]}" | \
    xargs -P 3 -I {} bash -c '
        IFS="|" read -r video_id url <<< "{}"
        oembed="https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=${video_id}&format=json"
        
        # Retry logic - try up to configured attempts
        max_attempts=$4
        attempt=1
        status=""
        
        while [[ $attempt -le $max_attempts ]]; do
            # Use simplified request for YouTube oEmbed API - does not need all browser headers
            response=$("$1" \
                -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Safari/537.36" \
                -H "Accept: application/json" \
                --compressed \
                --location \
                --max-redirs 10 \
                --connect-timeout 15 \
                --max-time 30 \
                -s \
                -w "\n__STATUS_CODE__%{http_code}" \
                "$oembed" 2>/dev/null | tr -d '\''\0'\'')
            status="${response##*__STATUS_CODE__}"
            
            # If successful, break out of retry loop
            if [[ "$status" == "200" ]]; then
                # Log if retry was successful (after initial failure)
                if [[ "$3" == "true" ]] && [[ $attempt -gt 1 ]]; then
                    echo "DEBUG: YouTube check succeeded for $url on attempt $attempt/$max_attempts" >&2
                fi
                break
            fi
            
            # Log retry attempts if debug is enabled
            if [[ "$3" == "true" ]] && [[ $attempt -lt $max_attempts ]]; then
                echo "DEBUG: YouTube check failed for $url (attempt $attempt/$max_attempts, status: $status), retrying..." >&2
            fi
            
            # Wait before retry (exponential backoff: 1s, 2s, 4s)
            if [[ $attempt -lt $max_attempts ]]; then
                sleep $((2 ** (attempt - 1)))
            fi
            
            ((attempt++))
        done
        
        # Report final result
        if [[ "$status" != "200" ]]; then
            # Include retry information in error message if all attempts failed
            echo "ERROR|$url|Video unavailable (HTTP ${status:-timeout} after $max_attempts attempts)"
        else
            echo "OK|$url|200"
        fi
        
        # Rate limiting between different videos
        sleep 1
    ' _ "$CURL_IMPERSONATE_BINARY" "unused" "$DEBUG" "$YOUTUBE_MAX_RETRIES" >> "$temp_youtube_results"
    
    # Process results from temp file (no subshell)
    while IFS='|' read -r result url status; do
        ((YOUTUBE_URLS_CHECKED++))
        if [[ "$result" == "ERROR" ]]; then
            ERROR_URL_LIST+=("$url")
            ERROR_TEXT_LIST+=("$status")
            ERROR_PARENT_LIST+=("${URL_PARENTS[$url]}")
            ((ERROR_COUNT++))
            ((YOUTUBE_ERRORS++))
            ERRORS_FOUND=true
        fi
    done < "$temp_youtube_results"
    
    # Cleanup
    rm -f "$temp_youtube_results"
    
    log_message "YouTube check complete: $YOUTUBE_URLS_CHECKED checked, $YOUTUBE_ERRORS errors"
}

#==============================================================================
# Report Generation
#==============================================================================

generate_report() {
    local base_url="$1"
    local cms_url="$2"
    
    local success_rate=100
    [[ $TOTAL_URLS -gt 0 ]] && success_rate=$(( (TOTAL_URLS - ERROR_COUNT) * 100 / TOTAL_URLS ))
    
    local duration="${CHECK_DURATION}s"
    [[ $CHECK_DURATION -ge 60 ]] && duration="$((CHECK_DURATION / 60))m $((CHECK_DURATION % 60))s"
    
    # Calculate additional statistics
    local false_positives=0
    local duplicates=0
    local youtube_checked="${YOUTUBE_URLS_CHECKED:-0}"
    local youtube_errors="${YOUTUBE_ERRORS:-0}"
    
    # Start HTML output
    cat <<'HTMLEOF'
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
HTMLEOF
    
    echo "<title>$LANG_SUBJECT</title>"
    
    cat <<HTMLEOF
<style>
body{font-family:Arial,sans-serif;margin:0;padding:0;background:#f5f5f5}
.container{max-width:1200px;margin:20px auto;background:white;padding:30px;border-radius:5px;box-shadow:0 2px 4px rgba(0,0,0,0.1)}
.header{text-align:center;margin-bottom:30px}
.logo{width:200px;height:auto;margin-bottom:20px}
h1{color:#333;font-size:28px;font-weight:normal;text-align:center;margin:10px 0 30px 0}
.intro-box{background:#f0f4f8;padding:20px;border-left:4px solid $THEME_COLOR;margin-bottom:30px;border-radius:5px}
.intro-box p{margin:0;color:#333;font-size:15px}
.intro-box a{color:$THEME_COLOR;text-decoration:none}
.intro-box a:hover{text-decoration:underline}
h2{color:#333;font-size:20px;border-bottom:2px solid $THEME_COLOR;padding-bottom:10px;margin:30px 0 20px 0}
.stats-table{width:100%;border-collapse:collapse;margin-bottom:30px}
.stats-table tr{border-bottom:1px solid #e0e0e0}
.stats-table tr:last-child{border-bottom:none}
.stats-table th{background:$THEME_COLOR;color:white;text-align:left;padding:12px;font-weight:normal;width:40%}
.stats-table td{padding:12px;color:#333;background:#f9f9f9}
.stats-table .error-count{color:#e74c3c;font-weight:bold}
.stats-table .warning-count{color:#f39c12;font-weight:bold}
.stats-table .success-rate{color:#27ae60;font-weight:bold}
.error-table{width:100%;border-collapse:collapse;margin-top:20px}
.error-table thead th{background:$THEME_COLOR;color:white;padding:12px;text-align:left;font-weight:normal}
.error-table tbody td{padding:10px;border-bottom:1px solid #e0e0e0}
.error-table tbody tr:hover{background:#f5f5f5}
.error-table tbody tr.css-error{background:#fff3e0}
.error-table tbody tr.protected-error{background:#f0f0f0}
.error-table a{color:$THEME_COLOR;text-decoration:none}
.error-table a:hover{text-decoration:underline}
.error-text{color:#e74c3c}
.info-box{background:#f0f0f0;padding:20px;border-radius:5px;margin:30px 0;border-left:4px solid #999}
.info-box h3{margin:0 0 10px 0;color:#333;font-size:16px;font-weight:bold}
.info-box p{margin:0;color:#555;font-size:14px;line-height:1.5}
.cms-box{background:#e3f2fd;padding:20px;border-radius:5px;margin:20px 0;border-left:4px solid #2196f3}
.cms-box h2{margin:0 0 10px 0;color:#1565c0;font-size:16px;font-weight:bold}
.cms-box p{margin:0;color:#333;font-size:14px;line-height:1.5}
.cms-box a{color:#1976d2;text-decoration:none;font-weight:500}
.cms-box a:hover{text-decoration:underline}
.loop-warning-box{background:#ffebee;padding:20px;border-left:4px solid #f44336;margin:30px 0;border-radius:5px}
.loop-warning-box h3{margin:0 0 10px 0;color:#c62828;font-size:18px;font-weight:bold}
.loop-warning-box p{margin:0;color:#333;font-size:14px;line-height:1.5}
.loop-table{width:100%;border-collapse:collapse;margin-top:20px}
.loop-table thead th{background:$THEME_COLOR;color:white;padding:12px;text-align:left;font-weight:normal}
.loop-table tbody td{padding:10px;border-bottom:1px solid #e0e0e0}
.loop-table tbody tr:hover{background:#f5f5f5}
.loop-table a{color:$THEME_COLOR;text-decoration:none;word-break:break-all}
.loop-table a:hover{text-decoration:underline}
.footer{text-align:center;margin-top:40px;padding-top:20px;border-top:1px solid #e0e0e0;color:#999;font-size:12px}
.footer p{margin:5px 0}
</style>
</head>
<body>
<div class="container">
<div class="header">
HTMLEOF
    echo "<img src=\"$LOGO_URL\" alt=\"$LOGO_ALT\" class=\"logo\">"
    echo "<h1>$LANG_INTRO_TITLE</h1>"
    cat <<'HTMLEOF'
</div>
<div class="intro-box">
HTMLEOF
    local intro_text=$(replace_placeholders "$LANG_INTRO_TEXT" "<a href=\"$base_url\">$base_url</a>" "")
    echo "<p>$intro_text</p>"
    cat <<'HTMLEOF'
</div>
HTMLEOF
    
    # Add CMS link section right after intro if provided
    if [[ "$cms_url" != "-" ]]; then
        echo "<div class=\"cms-box\">"
        echo "<h2>$LANG_CMS_TITLE</h2>"
        local cms_text=$(replace_placeholders "$LANG_CMS_TEXT" "" "<a href=\"$cms_url\">$cms_url</a>")
        echo "<p>$cms_text</p>"
        echo "</div>"
    fi
    
    # Add CSS error notice if report was redirected
    if [[ "$CSS_ERRORS_FOUND" == "true" ]] && [[ "$REDIRECT_CSS_ERRORS_TO_ADMIN" == "true" ]]; then
        cat <<'HTMLEOF'
<div class="info-box" style="border-left-color: #ff9800;">
    <h3>Developer Intervention Required</h3>
    <p>This report contains errors found in CSS files. Since CSS files require developer access to fix, this report has been sent to the web administrator instead of the regular recipient. The CSS errors are highlighted in orange in the table below.</p>
</div>
HTMLEOF
    fi
    
    # Add URL loop warning and list if detected (if enabled)
    if [[ "$URL_LOOPS_DETECTED" == "true" ]] && [[ "$URL_LOOP_ENABLE_WARNING" == "true" ]]; then
        echo "<div class=\"loop-warning-box\">"
        echo "<h3>$LANG_URL_LOOP_TITLE</h3>"
        echo "<p>$LANG_URL_LOOP_TEXT</p>"
        echo "</div>"

        # Show separated list of looping URLs
        if [[ ${#URL_LOOP_ALL_URLS[@]} -gt 0 ]]; then
            echo "<h2>$LANG_URL_LOOP_TABLE_HEADER</h2>"
            echo "<table class=\"loop-table\">"
            echo "<thead><tr><th>URL</th></tr></thead>"
            echo "<tbody>"
            IFS=$'\n' sorted_urls=($(printf '%s\n' "${URL_LOOP_ALL_URLS[@]}" | sort -u))
            unset IFS
            for url in "${sorted_urls[@]}"; do
                echo "<tr><td><a href=\"$url\">$url</a></td></tr>"
            done
            echo "</tbody>"
            echo "</table>"
        fi
    fi
    
    # Summary section with comprehensive statistics
    echo "<h2>$LANG_SUMMARY_TITLE</h2>"
    echo "<table class=\"stats-table\">"
    echo "<tr><th>$LANG_DURATION</th><td>$duration</td></tr>"
    echo "<tr><th>$LANG_TOTAL_URLS</th><td>$TOTAL_URLS</td></tr>"
    echo "<tr><th>$LANG_ERROR_URLS</th><td class=\"error-count\">$ERROR_COUNT</td></tr>"
    
    # Add duplicate errors count if any
    if [[ $ERROR_COUNT -gt 0 ]]; then
        # Count unique errors
        local unique_errors=$(printf "%s\n" "${ERROR_URL_LIST[@]}" | sort -u | wc -l)
        duplicates=$((ERROR_COUNT - unique_errors))
        [[ $duplicates -gt 0 ]] && echo "<tr><th>$LANG_DUPLICATE_ERRORS</th><td>$duplicates</td></tr>"
    fi
    
    # Add false positives if tracked
    [[ $false_positives -gt 0 ]] && echo "<tr><th>$LANG_FALSE_POSITIVES</th><td class=\"warning-count\">$false_positives</td></tr>"
    
    # Add YouTube statistics if checked
    if [[ $youtube_checked -gt 0 ]]; then
        echo "<tr><th>$LANG_YOUTUBE_CHECKED</th><td>$youtube_checked</td></tr>"
        [[ $youtube_errors -gt 0 ]] && echo "<tr><th>$LANG_YOUTUBE_UNAVAILABLE</th><td class=\"error-count\">$youtube_errors</td></tr>"
    fi
    
    echo "<tr><th>$LANG_SUCCESS_RATE</th><td class=\"success-rate\">${success_rate}%</td></tr>"
    echo "</table>"
    
    # Error details if any
    if [[ ${#ERROR_URL_LIST[@]} -gt 0 ]]; then
        echo "<h2>$LANG_DETAILS_TITLE</h2>"
        echo "<table class=\"error-table\">"
        echo "<thead>"
        echo "<tr><th>$LANG_COLUMN_PARENT</th><th>$LANG_COLUMN_ERROR</th><th>$LANG_COLUMN_URL</th></tr>"
        echo "</thead>"
        echo "<tbody>"
        
        local has_protected_errors=false
        for i in "${!ERROR_URL_LIST[@]}"; do
            local url="${ERROR_URL_LIST[$i]//&/&amp;}"
            local error="${ERROR_TEXT_LIST[$i]//&/&amp;}"
            local parent="${ERROR_PARENT_LIST[$i]//&/&amp;}"
            
            # Determine row class
            local row_class=""
            if [[ "$error" == *"$LANG_PROTECTION_DETECTED"* ]]; then
                row_class=" class=\"protected-error\""
                has_protected_errors=true
            elif [[ "$parent" =~ \.css(\?.*)?$ ]]; then
                row_class=" class=\"css-error\""
            fi
            
            echo "<tr$row_class>"
            # Handle empty or self-referencing parent URLs
            if [[ -z "$parent" ]] || [[ "$parent" == "$url" ]]; then
                echo "<td>-</td>"
            else
                echo "<td><a href=\"$parent\">$parent</a></td>"
            fi
            echo "<td class=\"error-text\">$error</td>"
            echo "<td><a href=\"$url\">$url</a></td>"
            echo "</tr>"
        done
        
        echo "</tbody>"
        echo "</table>"
        
        # Add info box for protected pages if any were found
        if [[ "$has_protected_errors" == "true" ]]; then
            echo "<div class=\"info-box\">"
            echo "<h3>$LANG_PROTECTION_TITLE</h3>"
            echo "<p>$LANG_PROTECTION_TEXT</p>"
            echo "</div>"
        fi
    fi
    
    # Footer
    echo "<div class=\"footer\">"
    echo "<p>$LANG_FOOTER_TEXT v$SCRIPT_VERSION</p>"
    echo "<p>$(date '+%d.%m.%Y %H:%M:%S')</p>"
    echo "</div>"
    echo "</div>"
    echo "</body>"
    echo "</html>"
}

send_email() {
    local mailto="$1"
    local base_url="$2"
    local html="$3"
    local subject_override="$4"  # Optional subject override
    
    local domain="${base_url#*://}"
    domain="${domain%%/*}"
    
    local subject="${subject_override:-$LANG_SUBJECT - $domain}"
    
    # Add URL loop warning to subject if detected (if enabled)
    if [[ "$URL_LOOPS_DETECTED" == "true" ]] && [[ -z "$subject_override" ]] && [[ "$URL_LOOP_ENABLE_WARNING" == "true" ]]; then
        subject="${subject}${LANG_URL_LOOP_SUBJECT_SUFFIX}"
    fi
    
    log_message "Sending email to: $mailto"
    
    if (
        echo "To: $mailto"
        echo "From: $MAIL_SENDER_NAME <$MAIL_SENDER>"
        echo "Subject: $subject"
        echo "Content-Type: text/html; charset=UTF-8"
        echo "MIME-Version: 1.0"
        echo ""
        echo "$html"
    ) | ${SENDMAIL_BINARY} -f "$MAIL_SENDER" "$mailto"; then
        log_message "Email sent"
        return 0
    else
        error_message "Email failed"
        return 1
    fi
}

generate_max_urls_report() {
    local base_url="$1"
    local max_urls="$2"
    local crawled_count="$3"
    local discovered_count="$4"
    
    # Replace placeholders in text
    local text=$(echo "$LANG_MAX_URLS_TEXT" | \
        sed "s|###base_url###|<a href=\"$base_url\">$base_url</a>|g" | \
        sed "s|###max_urls###|$max_urls|g" | \
        sed "s|###crawled_count###|$crawled_count|g" | \
        sed "s|###discovered_count###|$discovered_count|g")
    
    cat <<HTMLEOF
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>$LANG_MAX_URLS_SUBJECT</title>
<style>
body{font-family:Arial,sans-serif;margin:0;padding:0;background:#f5f5f5}
.container{max-width:1200px;margin:20px auto;background:white;padding:30px;border-radius:5px;box-shadow:0 2px 4px rgba(0,0,0,0.1)}
.header{text-align:center;margin-bottom:30px}
.logo{width:200px;height:auto;margin-bottom:20px}
h1{color:#333;font-size:28px;font-weight:normal;text-align:center;margin:10px 0 30px 0}
h2{color:#333;font-size:20px;border-bottom:2px solid $THEME_COLOR;padding-bottom:10px;margin:30px 0 20px 0}
.warning-box{background:#fff3e0;padding:20px;border-left:4px solid #ff9800;margin-bottom:30px}
.warning-box p{margin:0;color:#333;font-size:15px;line-height:1.6}
.warning-box a{color:$THEME_COLOR;text-decoration:none}
.warning-box a:hover{text-decoration:underline}
.loop-warning-box{background:#ffebee;padding:20px;border-left:4px solid #f44336;margin-bottom:30px}
.loop-warning-box h3{margin:0 0 10px 0;color:#c62828;font-size:18px;font-weight:bold}
.loop-warning-box p{margin:0;color:#333;font-size:14px;line-height:1.5}
.loop-table{width:100%;border-collapse:collapse;margin-top:20px}
.loop-table thead th{background:$THEME_COLOR;color:white;padding:12px;text-align:left;font-weight:normal}
.loop-table tbody td{padding:10px;border-bottom:1px solid #e0e0e0}
.loop-table tbody tr:hover{background:#f5f5f5}
.loop-table a{color:$THEME_COLOR;text-decoration:none;word-break:break-all}
.loop-table a:hover{text-decoration:underline}
.footer{text-align:center;margin-top:40px;padding-top:20px;border-top:1px solid #e0e0e0;color:#999;font-size:12px}
.footer p{margin:5px 0}
</style>
</head>
<body>
<div class="container">
<div class="header">
<img src="$LOGO_URL" alt="$LOGO_ALT" class="logo">
<h1>$LANG_MAX_URLS_TITLE</h1>
</div>
<div class="warning-box">
<p>$text</p>
</div>
HTMLEOF
    
    # Debug logging for troubleshooting
    debug_message "MAX_URLS report: URL_LOOPS_DETECTED=$URL_LOOPS_DETECTED, URL_LOOP_ALL_URLS count=${#URL_LOOP_ALL_URLS[@]}, URL_LOOP_ENABLE_WARNING=$URL_LOOP_ENABLE_WARNING"
    
    # Add URL loop detection results if any loops were found (if enabled)
    if [[ "$URL_LOOPS_DETECTED" == "true" ]] && [[ ${#URL_LOOP_ALL_URLS[@]} -gt 0 ]] && [[ "$URL_LOOP_ENABLE_WARNING" == "true" ]]; then
        echo "<div class=\"loop-warning-box\">"
        echo "<h3>$LANG_URL_LOOP_TITLE</h3>"
        echo "<p>$LANG_URL_LOOP_TEXT</p>"
        echo "</div>"
        
        # Create table with all URLs where loops were detected
        echo "<h2>$LANG_URL_LOOP_TABLE_HEADER</h2>"
        echo "<table class=\"loop-table\">"
        echo "<thead>"
        echo "<tr><th>URL</th></tr>"
        echo "</thead>"
        echo "<tbody>"
        
        # Sort loop URLs alphabetically for better readability
        if [[ ${#URL_LOOP_ALL_URLS[@]} -gt 0 ]]; then
            debug_message "Displaying ${#URL_LOOP_ALL_URLS[@]} loop URLs in table"
            IFS=$'\n' sorted_urls=($(printf '%s\n' "${URL_LOOP_ALL_URLS[@]}" | sort -u))
            unset IFS
            
            # Display sorted URLs
            for url in "${sorted_urls[@]}"; do
                echo "<tr><td><a href=\"$url\">$url</a></td></tr>"
            done
        else
            debug_message "No loop URLs to display in table"
            echo "<tr><td>No specific loop URLs collected</td></tr>"
        fi
        
        echo "</tbody>"
        echo "</table>"
    fi
    
    cat <<HTMLEOF
<div class="footer">
<p>$LANG_FOOTER_TEXT v$SCRIPT_VERSION</p>
<p>$(date '+%d.%m.%Y %H:%M:%S')</p>
</div>
</div>
</body>
</html>
HTMLEOF
}

#==============================================================================
# Debug Functions
#==============================================================================

display_excluded_urls_summary() {
    if [[ "$DEBUG" != "true" ]] || [[ ${#EXCLUDED_URL_LIST[@]} -eq 0 ]]; then
        return
    fi
    
    debug_message ""
    debug_message "=========================================="
    debug_message "=== EXCLUDED URLs SUMMARY ==="
    debug_message "=========================================="
    debug_message "Total excluded URLs: ${#EXCLUDED_URL_LIST[@]}"
    debug_message ""
    
    # Group by pattern
    declare -A pattern_counts
    declare -A pattern_examples
    
    for entry in "${EXCLUDED_URL_LIST[@]}"; do
        IFS='|' read -r url pattern <<< "$entry"
        ((pattern_counts["$pattern"]++))
        if [[ -z "${pattern_examples[$pattern]}" ]]; then
            pattern_examples["$pattern"]="$url"
        fi
    done
    
    # Display summary by pattern
    for pattern in "${!pattern_counts[@]}"; do
        debug_message "Pattern: '$pattern'"
        debug_message "  Matched: ${pattern_counts[$pattern]} URL(s)"
        debug_message "  Example: ${pattern_examples[$pattern]}"
        debug_message ""
    done
    
    debug_message "=========================================="
    debug_message ""
}

#==============================================================================
# Main
#==============================================================================

main() {
    debug_message "Starting v$SCRIPT_VERSION"
    
    parse_arguments "$@"
    
    [[ ${#REMAINING_ARGS[@]} -lt 4 ]] && die "Missing parameters"
    
    local base_url="${REMAINING_ARGS[0]}"
    local cms_url="${REMAINING_ARGS[1]}"
    local language="${REMAINING_ARGS[2]}"
    local mailto="${REMAINING_ARGS[3]}"
    
    validate_parameters "$base_url" "$cms_url" "$language" "$mailto"
    set_language_texts "$language"
    check_prerequisites
    
    # Extract domain for logging
    local domain="${base_url#*://}"
    domain="${domain%%/*}"
    CURRENT_DOMAIN="$domain"
    
    log_message "Starting check: $base_url (Workers: $PARALLEL_WORKERS, Batch: $BATCH_SIZE)"
    
    local start_time=$(date +%s)
    
    # Crawl
    debug_message "=== Phase 1: Crawling ==="
    crawl_website "$base_url" "$MAX_DEPTH"
    
    # Check URLs in parallel
    debug_message "=== Phase 2: Parallel Checking ==="
    check_urls_parallel "$base_url"
    
    # YouTube
    debug_message "=== Phase 3: YouTube ==="
    check_youtube_videos_parallel
    
    # URL Loop Detection
    debug_message "=== Phase 4: URL Loop Detection ==="
    detect_url_loops "$base_url"
    
    CHECK_DURATION=$(($(date +%s) - start_time))
    
    # Display excluded URLs summary before generating report
    display_excluded_urls_summary
    
    # Check if MAX_URLS was reached and send notification if configured
    if [[ "$MAX_URLS_REACHED" == "true" ]] && [[ "$SEND_REPORT_ON_MAX_URLS_REACHED" == "true" ]]; then
        log_message "Sending MAX_URLS notification to: $MAX_URLS_ADMIN_EMAIL"
        local max_urls_report=$(generate_max_urls_report "$base_url" "$MAX_URLS" "$MAX_URLS_CRAWLED_COUNT" "$MAX_URLS_DISCOVERED_COUNT")
        
        local domain="${base_url#*://}"
        domain="${domain%%/*}"
        local max_urls_subject="$LANG_MAX_URLS_SUBJECT - $domain"
        
        # Add URL loop warning to subject if detected (if enabled)
        if [[ "$URL_LOOPS_DETECTED" == "true" ]] && [[ "$URL_LOOP_ENABLE_WARNING" == "true" ]]; then
            max_urls_subject="${max_urls_subject}${LANG_URL_LOOP_SUBJECT_SUFFIX}"
        fi
        
        send_email "$MAX_URLS_ADMIN_EMAIL" "$base_url" "$max_urls_report" "$max_urls_subject"
    fi
    
    if [[ "$ERRORS_FOUND" != "true" ]]; then
        log_message "No errors found"
        return 0
    fi
    
    log_message "Generating report"
    local report=$(generate_report "$base_url" "$cms_url")
    
    # Determine recipient based on CSS errors
    local final_mailto="$mailto"
    if [[ "$CSS_ERRORS_FOUND" == "true" ]] && [[ "$REDIRECT_CSS_ERRORS_TO_ADMIN" == "true" ]]; then
        log_message "CSS errors detected - redirecting report to administrator: $CSS_ERROR_ADMIN_EMAIL"
        final_mailto="$CSS_ERROR_ADMIN_EMAIL"
        
        # Add note to report about redirection (optional - could be added to report generation)
        debug_message "Report redirected from $mailto to $CSS_ERROR_ADMIN_EMAIL due to CSS errors"
    fi
    
    send_email "$final_mailto" "$base_url" "$report"
    
    log_message "Complete (Duration: ${CHECK_DURATION}s)"
    return 0
}

# Entry
if [[ "${1:-}" =~ ^(-h|--help)$ ]]; then
    show_usage
    exit 0
fi

if [[ $# -eq 0 ]]; then
    show_usage
    exit 1
fi

main "$@"