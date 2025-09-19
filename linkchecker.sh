#!/bin/bash
set +H  # Disable history expansion to prevent issues with ! in AWK/Perl code

# Ensure the script runs with bash even if invoked via sh
if [ -z "${BASH_VERSION:-}" ]; then
  exec /bin/bash "$0" "$@"
fi

#==============================================================================
# LEXO Website Linkchecker Script - Modular Version
#==============================================================================
# Website link validation tool that crawls websites, checks for broken links,
# and sends detailed email reports. Uses curl-impersonate to handle modern
# web protection mechanisms.
#
# GitHub: https://github.com/lexo-ch/LinkChecker-Broken-Link-Finder-Email-Monitoring-Bash-Script
# Author: LEXO GmbH - https://www.lexo.ch
#==============================================================================

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/lib"

# Source all library files in numbered order for clear dependencies
# Foundation (00-01): Configuration and core utilities
source "$LIB_DIR/00-config-globals.lib"      # Global configuration and variables
source "$LIB_DIR/01-core-utilities.lib"      # Core utility functions

# URL Processing (02-03): Validation and extraction
source "$LIB_DIR/02-url-validator.lib"       # URL validation functions
source "$LIB_DIR/03-html-parser.lib"         # HTML parsing and URL extraction

# Network Operations (04-06): HTTP and content processors
source "$LIB_DIR/04-http-engine.lib"         # HTTP request engine with retry/pooling
source "$LIB_DIR/05-css-analyzer.lib"        # CSS file analysis
source "$LIB_DIR/06-youtube-validator.lib"   # YouTube video validation

# Core Logic (07-09): Crawling, scanning, and detection
source "$LIB_DIR/07-web-crawler.lib"         # Recursive website crawling
source "$LIB_DIR/08-page-scanner.lib"        # Single-page scanning
source "$LIB_DIR/09-loop-detector.lib"       # URL loop detection

# Output (10-11): Reporting and notifications
source "$LIB_DIR/10-report-generator.lib"    # HTML report generation
source "$LIB_DIR/11-email-sender.lib"        # Email notification sending

# Orchestration (12): Main controller
source "$LIB_DIR/12-main-orchestrator.lib"   # Main execution orchestrator

# Run main function
main "$@"