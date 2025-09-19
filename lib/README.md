# LinkChecker Library Architecture

## Overview

The LinkChecker uses a sophisticated modular library system consisting of 13 specialized components that work together to provide comprehensive link checking, crawling, and reporting capabilities. The architecture follows enterprise design patterns with clear separation of concerns and dependency management.

## Library Naming Convention

All libraries follow a **numbered category-function** pattern: `XX-category-function.lib`

- **XX**: Two-digit number (00-12) indicating load order and dependency hierarchy
- **category**: Functional category (config, core, url, html, http, etc.)
- **function**: Specific functionality (utilities, validator, parser, engine, etc.)

The numbering ensures correct load order and makes dependencies clear.

## Library Files

| File | Purpose | Key Functions |
|------|---------|---------------|
| **00-config-globals.lib** | Global configuration and variables | Branding/white-label config, language templates (DE/EN), performance tuning, URL exclusion patterns, binary file extensions, global data structures |
| **01-core-utilities.lib** | Core utility functions | `handle_interrupt()`, `die()`, `log_message()`, `debug_message()`, `error_message()`, `parse_arguments()`, `validate_parameters()`, `check_prerequisites()`, `extract_domain()`, `parse_http_response()`, `set_language_texts()` |
| **02-url-validator.lib** | URL validation and security | `normalize_url()`, `is_url_valid()`, `is_url_excluded()`, `is_url_in_scope()`, `validate_url_for_curl()`, `is_binary_file_url()` |
| **03-html-parser.lib** | HTML parsing and URL extraction | `extract_urls_from_html_optimized()` with Perl/AWK engines, custom attribute support for JS frameworks, srcset parsing |
| **04-http-engine.lib** | HTTP request engine | `create_curl_config()`, `http_request_pooled()`, `http_request_with_retry()`, `check_url_worker()`, `check_urls_parallel()`, connection pooling, exponential backoff |
| **05-css-analyzer.lib** | CSS file analysis | `extract_urls_from_css()` |
| **06-youtube-validator.lib** | YouTube video validation | `check_youtube_videos_parallel()` via oEmbed API, retry logic, rate limiting, multiple URL format support |
| **07-web-crawler.lib** | Recursive website crawling | `crawl_website()`, `process_discovered_url()`, `process_css_files()`, intelligent queue management, MAX_URLS enforcement |
| **08-page-scanner.lib** | Single-page scanning | `scan_single_page()` without recursion |
| **09-loop-detector.lib** | URL pattern loop detection | `detect_url_loops()` with 3-method algorithm, `display_excluded_urls_summary()` |
| **10-report-generator.lib** | HTML report generation | `generate_report()`, `generate_max_urls_report()`, theme customization, responsive templates, loop warning integration |
| **11-email-sender.lib** | Email notifications | `send_email()` with MIME formatting, subject line modification for URL loops |
| **12-main-orchestrator.lib** | Main execution controller | `main()` with 4-phase execution model, report routing logic |

## Load Order Dependencies

```
00-config-globals.lib      (no dependencies)
01-core-utilities.lib      (requires: 00)
02-url-validator.lib       (requires: 00, 01)
03-html-parser.lib         (requires: 00, 01, 02)
04-http-engine.lib         (requires: 00, 01, 02)
05-css-analyzer.lib        (requires: 00, 01, 02)
06-youtube-validator.lib   (requires: 00, 01, 04)
07-web-crawler.lib         (requires: 00-06)
08-page-scanner.lib        (requires: 00-06)
09-loop-detector.lib       (requires: 00, 01)
10-report-generator.lib    (requires: 00, 01)
11-email-sender.lib        (requires: 00, 01)
12-main-orchestrator.lib   (requires: all)
```

## Key Technical Features

### Parallel Processing Architecture
- Worker pool implementation for concurrent URL checking
- Configurable parallelism levels (default: 20 workers)
- Connection pooling for HTTP requests
- Separate parallel processing for YouTube validation

### Advanced URL Loop Detection
Three-method algorithm for detecting infinite URL patterns:
1. **Consecutive Segment Repetition**: Detects patterns like `/page/page/page/`
2. **Multi-Segment Pattern Repetition**: Finds complex patterns like `/a/b/c/a/b/c/`
3. **Regular Interval Repetition**: Identifies patterns at fixed intervals

### Security Features
- URL validation against command injection
- Protection against directory traversal
- Binary file exclusion to prevent resource waste
- Scope validation for domain restrictions

### HTML Parsing Engine
- Dual-engine support: Perl (fast) and AWK (fallback)
- Custom attribute extraction for JavaScript frameworks
- Srcset parsing for responsive images
- Malformed URL detection and reporting

### Error Handling & Resilience
- Exponential backoff retry logic
- Graceful interrupt handling (Ctrl+C)
- Comprehensive error logging
- Connection timeout management

## Execution Flow

The main orchestrator implements a 4-phase execution model:

1. **Discovery Phase**
   - Website crawling or single-page scanning
   - URL extraction from HTML and CSS
   - Queue building for validation

2. **Validation Phase**
   - Parallel HTTP validation of discovered URLs
   - Connection pooling for efficiency
   - Error categorization and tracking

3. **YouTube Verification Phase**
   - Separate validation for YouTube videos
   - oEmbed API integration
   - Rate-limited requests

4. **Analysis & Reporting Phase**
   - URL loop detection
   - Report generation
   - Email notification (if configured)

## Global Data Structures

```bash
# Primary arrays
declare -a ERROR_URLS           # Failed URLs
declare -a ERROR_STATUS_CODES   # HTTP status codes
declare -a ERROR_STATUS_TEXTS   # Status descriptions
declare -a ERROR_FOUND_ON       # Source pages

# Associative arrays
declare -A VISITED_URLS         # Deduplication
declare -A FAILED_URLS          # Error tracking
declare -A YOUTUBE_VIDEOS       # YouTube URL collection

# Queue management
declare -a URL_QUEUE            # Processing queue
```

## Performance Tuning

Key configuration parameters in `00-config-globals.lib`:
- `MAX_PARALLEL_JOBS`: Worker pool size (default: 20)
- `MAX_URLS`: Crawl limit (default: 500)
- `YOUTUBE_CHECK_MAX_PARALLEL`: YouTube parallel checks (default: 10)
- `HTTP_TIMEOUT`: Request timeout in seconds
- `MAX_RETRY_ATTEMPTS`: Retry count for failed requests

## Architecture Benefits

1. **Clear Dependencies**: Numbered prefix shows load order
2. **Self-Documenting**: Names clearly indicate functionality
3. **Maintainable**: Easy to locate and modify specific functionality
4. **Scalable**: New libraries can be inserted with appropriate numbering
5. **Professional**: Follows enterprise naming conventions
6. **Testable**: Modular design enables unit testing
7. **Performant**: Parallel processing and connection pooling
8. **Resilient**: Comprehensive error handling and retry logic

## Extending the Architecture

### Adding a New Library

1. Choose appropriate number based on dependencies
2. Follow naming convention: `XX-category-function.lib`
3. Include header comment with purpose and dependencies
4. Export functions using consistent naming
5. Update this README with the new library

### Best Practices

- Keep functions focused on single responsibility
- Use consistent error handling patterns
- Log debug messages for troubleshooting
- Validate inputs and handle edge cases
- Document complex algorithms inline
- Follow existing code style and conventions