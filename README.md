# LEXO Website Linkchecker v2.4

A professional website link validation system built in Bash that overcomes modern web protection mechanisms. Features intelligent crawling, parallel processing, and sophisticated HTML email reporting with white-label branding capabilities.

## 🚀 What's New in v2.4

### Enhanced URL Detection & Validation
- **Custom HTML Attributes Support**: Automatically extracts URLs from custom attributes like `data-href`, `data-src`, `ng-href`, `ng-src`, and other framework-specific attributes
- **Intelligent URL Validation**: Detects and filters malformed URLs, repeating patterns (e.g., Facebook widget loops), and excessive query parameters
- **Smart HTTP Method Selection**: Uses GET for external URLs and HEAD for internal URLs with automatic fallback for better compatibility

### Advanced Error Handling
- **CSS Error Detection & Routing**: Automatically detects errors in CSS files and can redirect reports to web administrators instead of customers
- **YouTube Retry Logic**: Implements automatic retry with exponential backoff for YouTube oEmbed API checks to reduce false positives
- **Enhanced Protection Detection**: Improved detection of CDN/WAF protection with configurable exclusion from error reports

### Improved Customization
- **Theme Color Configuration**: Single `THEME_COLOR` variable to customize the primary color throughout email reports
- **Extended Language Templates**: Comprehensive multi-language support with dynamic placeholders for base URL and CMS URL
- **Expanded Default Exclusions**: More comprehensive exclude patterns including social media platforms and common CDN resources

### Developer Features
- **Debug Mode Enhancements**: Excluded URLs summary with pattern grouping for better debugging
- **Configurable Retry Attempts**: Customizable maximum retry attempts for YouTube video checks
- **URL Length Limits**: Configurable maximum URL length to prevent processing of malformed or infinite URLs

## ✨ Core Features

- **Intelligent Website Crawling**: Discovers links from HTML, CSS, and custom attributes in JavaScript frameworks
- **Advanced Link Validation**: Parallel HTTP requests with smart HEAD/GET method selection
- **YouTube Video Validation**: Checks video availability with automatic retry and exponential backoff
- **Professional Email Reports**: Responsive HTML emails with customizable theme colors and branding
- **CSS Error Management**: Automatic detection and routing of CSS-related errors to developers
- **Protection-Aware Checking**: Identifies and properly handles CDN-protected websites
- **URL Validation Engine**: Filters malformed URLs, infinite loops, and excessive parameters
- **Flexible Configuration**: Extensive command-line options and environment variables
- **Enterprise Logging**: Comprehensive audit trails with timestamp and domain context
- **Integration Ready**: Designed for cron jobs, CI/CD pipelines, and monitoring systems

## 📋 Prerequisites

### Required Software

**curl-impersonate-chrome** (Essential for protection bypass):
```bash
# Download and install curl-impersonate
wget https://github.com/lwthiker/curl-impersonate/releases/latest/download/curl-impersonate-chrome-linux-x86_64.tar.gz
tar -xzf curl-impersonate-chrome-linux-x86_64.tar.gz
sudo cp curl-impersonate-chrome /usr/local/bin/
```

**System Tools**:
```bash
# Ubuntu/Debian
sudo apt-get install sendmail xargs awk grep

# CentOS/RHEL
sudo yum install sendmail xargs gawk grep

# macOS (with Homebrew)
brew install gnu-awk grep
```

### System Requirements
- **Bash 4.0+** (for associative arrays)
- **curl-impersonate-chrome** (for protection bypass)
- **sendmail** (for email delivery)
- **Standard Unix tools**: awk, grep, xargs, sort, head, tail

## ⚙️ Installation & Setup

### 1. Download the Script
```bash
wget https://raw.githubusercontent.com/lexo-ch/LinkChecker-Broken-Link-Finder-Email-Monitoring-Bash-Script/main/linkchecker.sh
chmod +x linkchecker.sh
```

### 2. Install curl-impersonate
```bash
# Create curl directory in script location
mkdir -p curl
cd curl

# Download curl-impersonate
wget https://github.com/lwthiker/curl-impersonate/releases/latest/download/curl-impersonate-chrome-linux-x86_64.tar.gz
tar -xzf curl-impersonate-chrome-linux-x86_64.tar.gz

# Make executable
chmod +x curl-impersonate-chrome
cd ..
```

### 3. Configure White-Label Branding
Edit the script's branding section:
```bash
# White-label configuration
SCRIPT_NAME="Your Company Linkchecker"
LOGO_URL="https://yourcompany.com/logo.png"
LOGO_ALT="Your Company Logo"
MAIL_SENDER="websupport@yourcompany.com"
MAIL_SENDER_NAME="Your Company | Web Support"

# Theme Color Configuration (v2.4+)
THEME_COLOR="#832883"  # Change this to customize report colors
```

### 4. Set Up Email (SMTP)
```bash
# Install and configure Postfix
sudo apt-get install postfix

# Configure SMTP relay in /etc/postfix/main.cf
relayhost = your.smtp.server:587
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/saslpass
smtp_use_tls = yes
```

### 5. Create Log Directory
```bash
# Create log file with proper permissions
sudo touch /var/log/linkchecker.log
sudo chmod 666 /var/log/linkchecker.log

# Or use custom location
export LOG_FILE="/path/to/your/linkchecker.log"
```

## 🚀 Usage

### Command Syntax
```bash
./linkchecker.sh [OPTIONS] <base_url> <cms_login_url> <language> <mailto>
```

### Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `base_url` | Website URL to check | `https://example.com` |
| `cms_login_url` | CMS login URL (use `-` if none) | `https://example.com/admin` or `-` |
| `language` | Report language (`de` or `en`) | `de` |
| `mailto` | Email recipients (comma-separated) | `admin@example.com,team@example.com` |

### Command-Line Options

| Option | Description | Default | Example |
|--------|-------------|---------|---------|
| `--exclude=REGEX` | Add URL exclusion pattern | - | `--exclude='\.pdf$'` |
| `--max-depth=N` | Maximum crawl depth | Unlimited | `--max-depth=3` |
| `--max-urls=N` | Maximum URLs to check | Unlimited | `--max-urls=1000` |
| `--parallel=N` | Number of parallel workers | 20 | `--parallel=10` |
| `--batch-size=N` | URLs per processing batch | 50 | `--batch-size=25` |
| `--debug` | Enable debug output | false | `--debug` |
| `-h, --help` | Show help message | - | `-h` |

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DEBUG` | Enable debug mode | `false` |
| `LOG_FILE` | Log file location | `/var/log/linkchecker.log` |
| `PARALLEL_WORKERS` | Number of workers | `20` |
| `BATCH_SIZE` | Batch processing size | `50` |
| `MAX_DEPTH` | Crawl depth limit | `50` |
| `MAX_URLS` | URL check limit | `15000` |
| `MAX_URL_LENGTH` | Maximum URL length to process | `2000` |
| `EXCLUDE_PROTECTED_FROM_REPORT` | Hide protected pages from reports | `false` |
| `REDIRECT_CSS_ERRORS_TO_ADMIN` | Redirect CSS error reports to admin | `false` |
| `CSS_ERROR_ADMIN_EMAIL` | Admin email for CSS errors | `yoursupportmail@yourcompany.tld` |
| `YOUTUBE_MAX_RETRIES` | Maximum retry attempts for YouTube checks | `3` |
| `THEME_COLOR` | Primary color for email reports | `#832883` |

## 📖 Usage Examples

### Basic Website Check
```bash
./linkchecker.sh https://example.com - en webmaster@example.com
```

### WordPress Site with Admin Panel
```bash
./linkchecker.sh https://myblog.com https://myblog.com/wp-admin de admin@myblog.com
```

### Performance-Optimized Check
```bash
./linkchecker.sh --parallel=30 --batch-size=100 --max-depth=5 https://example.com - en admin@example.com
```

### With Custom Exclusions
```bash
./linkchecker.sh \
  --exclude='\.pdf$' \
  --exclude='/api/' \
  --exclude='\/wp-admin\/' \
  https://example.com - en admin@example.com
```

### Debug Mode with Custom Settings
```bash
DEBUG=true PARALLEL_WORKERS=10 ./linkchecker.sh --debug https://example.com - en admin@example.com
```

### Enterprise Configuration
```bash
./linkchecker.sh \
  --parallel=20 \
  --batch-size=50 \
  --max-urls=5000 \
  --exclude='\.pdf$' \
  --exclude='/downloads/' \
  https://company.com https://company.com/cms en "dev@company.com,manager@company.com"
```

## 🎛️ Advanced Configuration

### URL Exclusion Patterns
Customize exclusion patterns in the script (expanded in v2.4):
```bash
EXCLUDES=(
    "\/xmlrpc\.php"                    # WordPress XML-RPC
    "\/wp-json\/"                      # WordPress REST API
    "\/feed\/"                         # RSS feeds
    "\?p=[0-9]+"                       # WordPress post IDs
    "bootstrap\.min\.css"              # Bootstrap CDN
    "googletagmanager\.com\/gtag\/js"  # Google Analytics
    "google\.com\/recaptcha\/api\.js"  # Google reCAPTCHA
    "google\.com\/maps"                # Google Maps
    "leaflet\.css"                     # Leaflet maps
    "jquery\.mCustomScrollbar\.min\.css" # jQuery plugins
    "https:\/\/(www\.)?linkedin\.com"  # LinkedIn (often blocked)
)
```

### Custom HTML Attributes (v2.4+)
Configure custom attributes to check for URLs:
```bash
CUSTOM_ATTR_INCLUDES=(
    "data-href"        # JavaScript modal windows
    "data-src"         # Lazy-loaded images
    "data-url"         # Custom widgets
    "ng-href"          # Angular framework
    "ng-src"           # Angular images
    "ng-srcset"        # Angular responsive images
)
```

### Performance Tuning
```bash
# High-performance configuration
export PARALLEL_WORKERS=30
export BATCH_SIZE=100
export CONNECTION_CACHE_SIZE=10000

# Conservative configuration for slower servers
export PARALLEL_WORKERS=5
export BATCH_SIZE=20
export REQUEST_DELAY=1
```

### Protection Detection Settings
```bash
# Exclude protected pages from error reports
export EXCLUDE_PROTECTED_FROM_REPORT=true

# Custom curl-impersonate binary location
export CURL_IMPERSONATE_BINARY="/usr/local/bin/curl-impersonate-chrome"
```

### CSS Error Handling (v2.4+)
```bash
# Redirect reports with CSS errors to developers
export REDIRECT_CSS_ERRORS_TO_ADMIN=true
export CSS_ERROR_ADMIN_EMAIL="developer@yourcompany.com"

# CSS errors require developer access and can't be fixed by content editors
```

### YouTube Check Configuration (v2.4+)
```bash
# Configure retry attempts for YouTube API
export YOUTUBE_MAX_RETRIES=3  # Try up to 3 times
export YOUTUBE_OEMBED_DELAY=1  # Delay between checks
```

## 📧 Email Reports

### Report Features
- **Executive Summary**: Duration, URLs checked, success rate, error counts
- **YouTube Analytics**: Video availability statistics with retry information
- **Detailed Error Tables**: Clickable links with error descriptions and source pages
- **Protection Detection**: Special handling for CDN-protected pages
- **CSS Error Highlighting**: Orange highlighting for CSS-related errors (v2.4+)
- **Developer Routing**: Automatic redirection of CSS error reports to admins (v2.4+)
- **Mobile Responsive**: Professional design optimized for all devices
- **Theme Customization**: Single-variable color theming throughout reports (v2.4+)
- **White-Label Branding**: Customizable logos and company information
- **Debug Summary**: Pattern-grouped excluded URLs summary (v2.4+)

### Language Customization
Modify language templates in the script:
```bash
# German templates
LANG_DE_SUBJECT="Defekte Links auf der Website gefunden"
LANG_DE_INTRO_TITLE="Fehlerhafte Links auf Ihrer Webseite entdeckt"

# English templates  
LANG_EN_SUBJECT="Broken Links Found on Website"
LANG_EN_INTRO_TITLE="Broken Links Discovered on Your Website"
```

### Report Sections
1. **Header**: Company logo and title
2. **Introduction**: Website overview with actionable guidance
3. **CMS Access**: Direct login link (if provided)
4. **Statistics Table**: Comprehensive metrics and performance data
5. **Error Details**: Sortable table with broken links and sources
6. **Protection Info**: Explanation of CDN protection detection
7. **Footer**: Branding and generation timestamp

## 🕐 Automated Monitoring

### CRON Examples

**Daily comprehensive check:**
```bash
0 2 * * * /path/to/linkchecker.sh https://example.com - en admin@example.com
```

**Weekly deep scan:**
```bash
0 3 * * 0 /path/to/linkchecker.sh --parallel=30 --max-depth=10 https://example.com - de admin@example.com
```

**Multiple sites with different configurations:**
```bash
# E-commerce site (exclude shopping cart)
0 2 * * * /path/to/linkchecker.sh --exclude='/cart/' --exclude='/checkout/' https://shop.com - en shop@company.com

# Blog site (exclude admin and feeds)
0 3 * * * /path/to/linkchecker.sh --exclude='/wp-admin/' --exclude='/feed/' https://blog.com - en blog@company.com

# Corporate site (comprehensive check)
0 4 * * * /path/to/linkchecker.sh --parallel=25 --max-urls=2000 https://corp.com - en corp@company.com
```

**Error handling and notifications:**
```bash
# With error logging
0 2 * * * /path/to/linkchecker.sh https://example.com - en admin@example.com 2>> /var/log/linkchecker-errors.log

# With failure notification
0 2 * * * /path/to/linkchecker.sh https://example.com - en admin@example.com || echo "Linkchecker failed" | mail -s "Linkchecker Error" admin@example.com
```

## 🔧 Why curl-impersonate?

Modern websites use sophisticated protection mechanisms that block traditional automated tools:

### Protection Mechanisms
- **CDN Protection**: Cloudflare, AWS CloudFront actively fingerprint requests
- **WAF Filtering**: Web Application Firewalls detect bot traffic patterns
- **Bot Detection**: JavaScript-based systems analyze browser behavior
- **Rate Limiting**: Aggressive throttling of non-browser agents

### curl-impersonate Advantages
- **Authentic Browser Mimicking**: Real Chrome TLS fingerprints and HTTP/2 behavior
- **Advanced Standards Support**: HTTP/2, ALPS, certificate compression
- **Protection Bypass**: Circumvents most bot detection mechanisms
- **Reliable Access**: Ensures consistent results across protected websites

### Limitations & Advanced Protection Handling

While curl-impersonate significantly improves access to protected websites, some advanced CDN protections still present challenges:

**JavaScript-Based Protection**: Some CDN systems (particularly advanced Cloudflare configurations) require active JavaScript execution and browser interaction that cannot be replicated by curl-impersonate alone. These protections may include:
- Browser challenge pages requiring JavaScript computation
- Advanced fingerprinting requiring DOM manipulation
- Time-based challenges requiring multi-step interactions

**Intelligent Detection & Reporting**: The script automatically detects these advanced protection mechanisms and handles them intelligently:
- **Smart Recognition**: Identifies challenge pages and JavaScript-required protections
- **Clear Reporting**: Marks protected URLs with "(page protection detected)" in reports
- **Contextual Information**: Provides explanatory text about what protection detection means
- **Optional Exclusion**: Configure `EXCLUDE_PROTECTED_FROM_REPORT=true` to hide protected pages from error reports

This approach ensures that reports focus on actual broken links while providing transparency about protection-related limitations.

### Before vs. After
```bash
# Traditional approach (often blocked)
curl -I https://protected-site.com
# Result: 403 Forbidden, 503 Service Unavailable

# curl-impersonate approach (works reliably)
curl-impersonate-chrome -I https://protected-site.com  
# Result: 200 OK with actual website response (or intelligent protection detection)
```

## 🛠️ Troubleshooting

### Common Issues

**"curl-impersonate not found"**
```bash
# Check binary location
ls -la ./curl/curl-impersonate-chrome
chmod +x ./curl/curl-impersonate-chrome

# Or set custom path
export CURL_IMPERSONATE_BINARY="/usr/local/bin/curl-impersonate-chrome"
```

**"Cannot write to log file"**
```bash
# Fix permissions
sudo touch /var/log/linkchecker.log
sudo chmod 666 /var/log/linkchecker.log

# Or use custom location
export LOG_FILE="/home/user/linkchecker.log"
```

**High memory usage**
```bash
# Reduce parallel workers and batch size
./linkchecker.sh --parallel=5 --batch-size=20 https://example.com - en admin@example.com

# Set URL limits
./linkchecker.sh --max-urls=1000 --max-depth=3 https://example.com - en admin@example.com
```

**Protected pages still showing as errors**
```bash
# Exclude protected pages from reports
export EXCLUDE_PROTECTED_FROM_REPORT=true
./linkchecker.sh https://example.com - en admin@example.com

# Protected pages will be detected but not included in error count
# Check logs to see detection messages
tail -f /var/log/linkchecker.log | grep "protection detected"
```

**Slow performance**
```bash
# Optimize for speed
./linkchecker.sh --parallel=30 --batch-size=100 https://example.com - en admin@example.com

# Check connection cache settings
export CONNECTION_CACHE_SIZE=10000
```

### Debug Mode
Enable comprehensive debugging:
```bash
# Command-line debug
./linkchecker.sh --debug https://example.com - en admin@example.com

# Environment variable debug
DEBUG=true ./linkchecker.sh https://example.com - en admin@example.com

# Real-time log monitoring
tail -f /var/log/linkchecker.log
```

### Performance Monitoring
```bash
# Monitor system resources during check
top -p $(pgrep -f linkchecker.sh)

# Check network connections
netstat -an | grep :80 | wc -l
netstat -an | grep :443 | wc -l

# Monitor log file growth
watch -n 1 'wc -l /var/log/linkchecker.log'
```

## 📊 Performance Optimization

### Recommended Settings by Website Size

**Small websites (< 100 pages):**
```bash
PARALLEL_WORKERS=5
BATCH_SIZE=25
MAX_URLS=500
```

**Medium websites (100-1000 pages):**
```bash
PARALLEL_WORKERS=15
BATCH_SIZE=50
MAX_URLS=2000
```

**Large websites (1000+ pages):**
```bash
PARALLEL_WORKERS=25
BATCH_SIZE=100
MAX_URLS=5000
CONNECTION_CACHE_SIZE=10000
```

### Memory Management
```bash
# Monitor memory usage
watch -n 1 'ps aux | grep linkchecker.sh'

# Optimize for low memory systems
export PARALLEL_WORKERS=3
export BATCH_SIZE=10
export CONNECTION_CACHE_SIZE=1000
```

## 📈 Enterprise Integration

### CI/CD Pipeline Integration
```yaml
# GitLab CI example
linkcheck:
  stage: test
  script:
    - ./linkchecker.sh https://staging.example.com - en devops@example.com
  only:
    - master
```

### Monitoring Integration
```bash
# Nagios/Icinga check
if ! ./linkchecker.sh https://example.com - en admin@example.com; then
    echo "CRITICAL - Linkchecker failed"
    exit 2
fi
```

### API Integration
```bash
# Webhook notification on completion
./linkchecker.sh https://example.com - en admin@example.com
curl -X POST https://hooks.slack.com/... -d "Linkcheck completed for example.com"
```

## 🔄 Version History

### v2.4 (2025-08-20) - Enhanced Detection & Customization
- 🎯 **Custom Attribute Support**: Extract URLs from framework-specific HTML attributes
- 🔄 **YouTube Retry Logic**: Automatic retry with exponential backoff for API checks
- 🎨 **Theme Color System**: Single-variable color customization for reports
- 📧 **CSS Error Routing**: Automatic redirection of CSS errors to developers
- 🛡️ **Smart HTTP Methods**: Optimized HEAD/GET selection based on URL type
- 🔍 **URL Validation Engine**: Detection of malformed URLs and infinite loops
- 📊 **Debug Enhancements**: Pattern-grouped excluded URLs summary
- 🌐 **Extended Exclusions**: Comprehensive default patterns for social media and CDNs

### v2.0 (2025-08-18) - Complete Rewrite
- 🚀 **curl-impersonate Integration**: Revolutionary protection bypass technology
- ⚡ **Parallel Processing**: Configurable worker pools and batch processing
- 🎨 **White-Label Branding**: Full customization support for organizations
- 🔍 **Advanced Protection Detection**: Intelligent Cloudflare/CDN handling
- 📊 **Performance Optimization**: Connection pooling, caching, single-pass parsing
- 🌐 **Enhanced Multi-Language**: Professional German and English templates
- 🛠️ **Enterprise Features**: Comprehensive configuration and monitoring
- 📧 **Professional Reporting**: Responsive HTML emails with detailed analytics

### Previous Versions
- v1.6 (2025-08-01): Sendmail integration improvements
- v1.5 (2025-07-30): Email header enhancements  
- v1.4 (2025-07-28): YouTube checking and CRON optimization
- v1.0 (2025-07-03): Initial release

## 📄 License

No license, no warranties, use however you like.

## 🏆 Acknowledgments

- Built with **curl-impersonate** by [lwthiker](https://github.com/lwthiker/curl-impersonate)
- YouTube validation using **YouTube oEmbed API**
- Inspired by enterprise website monitoring requirements
- Designed for system administrators, DevOps teams, and web developers

## 🤝 Contributing

Contributions welcome! Please feel free to submit issues, feature requests, or pull requests.

### Development Setup
```bash
# Clone repository
git clone https://github.com/lexo-ch/LinkChecker-Broken-Link-Finder-Email-Monitoring-Bash-Script.git
cd LinkChecker-Broken-Link-Finder-Email-Monitoring-Bash-Script

# Set up development environment
chmod +x linkchecker.sh
mkdir -p curl logs

# Run tests
DEBUG=true ./linkchecker.sh --help
```

## 📞 Support

Generally, there's no support. Everyone can use it freely, extend or modify it and use it at own risk. You can open an issue on Github but we're not promising active support. We might though. Depends on the weather ;)
- Open an issue on GitHub: https://github.com/lexo-ch/LinkChecker-Broken-Link-Finder-Email-Monitoring-Bash-Script/issues
- Contact: websupport@lexo.ch
- Documentation: See script comments for technical details
