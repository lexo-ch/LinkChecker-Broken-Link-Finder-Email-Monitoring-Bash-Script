# Automated website link checker with HTML email reporting

A robust Bash script that crawls your website, detects broken links, validates YouTube videos, and sends beautifully formatted HTML email reports. Perfect for automated monitoring via CRON jobs.

## ✨ Features

- **Comprehensive Link Checking**: Crawls internal and external links recursively with configurable depth
- **YouTube Video Validation**: Automatically checks YouTube video availability using oEmbed API
- **Professional Email Reports**: HTML emails with responsive design and detailed statistics  
- **Flexible Exclusion System**: REGEX-based URL exclusion patterns with runtime configuration
- **Enhanced CRON Support**: Silent operation with proper error handling for automated scheduling
- **Bilingual Support**: German and English report languages
- **Command-Line Options**: Dynamic exclude patterns, debug mode, and help system
- **Rate-Limited API Calls**: Respects YouTube API limits with intelligent throttling
- **Detailed Logging**: Configurable debug levels with comprehensive audit trails
- **UTF-8 Compatible**: Proper encoding for international content
- **Mobile-Friendly**: Responsive email templates that work on all devices

## 📋 Prerequisites

### Required Packages
```bash
# Ubuntu/Debian
sudo apt-get install linkchecker mailutils curl

# CentOS/RHEL
sudo yum install linkchecker mailx curl

# macOS (with Homebrew)
brew install linkchecker curl
```

### System Requirements
- **Bash 4.0+** (for array support)
- **linkchecker** (Python-based link checking tool)
- **curl** (for YouTube video validation)
- **sendmail** (for sending emails - preferred method)
- **Configured SMTP MTA** (see Email Setup below)

## 📧 Email Setup

The script uses `sendmail` directly for reliable email delivery with proper header control. This approach avoids duplicate headers and provides better compatibility across different systems.

### Postfix Configuration (Recommended)

The script is configured to use `sendmail` directly, which provides the most reliable email delivery. Install and configure Postfix (which provides the `sendmail` command):

```bash
# Install Postfix
sudo apt-get install postfix

# Choose "Internet Site" during installation
```

#### Configure Postfix

Create a basic `/etc/postfix/main.cf` configuration:
```bash
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/saslpass
smtp_sasl_security_options = noanonymous
relayhost = your.smtpgateway.tld:587
myhostname = myhost.domain.tld
mydomain = domain.tld
smtp_use_tls = yes
```

#### Set Up SMTP Authentication

Create `/etc/postfix/saslpass` with your SMTP credentials:
```bash
your.smtpgateway.tld		yourusername@example.tld:yourpassword
```

Apply the configuration:
```bash
# Initialize the password database
sudo postmap /etc/postfix/saslpass

# Secure the password files
sudo chmod 600 /etc/postfix/saslpass /etc/postfix/saslpass.db

# Restart Postfix
sudo systemctl restart postfix
```

### Email Configuration in Script

The script uses `sendmail` directly with proper header formatting to avoid duplicate `From:` headers and ensure correct `Return-Path` settings. The email configuration variables in the script are:

```bash
# Email configuration
MAIL_SENDER="youremail@example.tld"
MAIL_SENDER_NAME="Your Name | Web Support"
```

### Test Email Configuration

Test your email setup using sendmail:
```bash
# Test sendmail directly
echo -e "From: test@example.tld\nSubject: Test Subject\nTo: youremail@example.tld\n\nTest message" | sendmail -f test@example.tld youremail@example.tld

# Check mail queue
mailq

# Check mail logs
sudo tail -f /var/log/mail.log
```

## 🚀 Quick Start

### 1. Download the Script
```bash
wget https://raw.githubusercontent.com/lexo-ch/LinkChecker-Broken-Link-Finder-Email-Monitoring-Bash-Script/refs/heads/master/linkchecker.sh
chmod +x linkchecker.sh
```

### 2. Configure Email Settings
Edit the script and modify these variables:
```bash
# Email configuration
MAIL_SENDER="youremail@example.tld"
MAIL_SENDER_NAME="Your Name | Web Support"
```

Also ensure your SMTP MTA is configured (see [Email Setup](#-email-setup) section).

### 3. Basic Usage
```bash
./linkchecker.sh https://example.com - en admin@example.com
```

## 📖 Detailed Usage

### Command Syntax
```bash
./linkchecker.sh [OPTIONS] <base_url> <cms_login_url> <language> <mailto>
```

### Options (New since v1.4)

| Option | Description | Example |
|--------|-------------|---------|
| `--exclude=REGEX` | Add exclude pattern (can be used multiple times) | `--exclude='\.pdf$'` |
| `--debug` | Enable debug output | `--debug` |
| `-h, --help` | Show help message | `-h` |

### Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `base_url` | Website URL to check | `https://example.com` |
| `cms_login_url` | CMS login URL (use `-` if none) | `https://example.com/admin` or `-` |
| `language` | Report language (`de` or `en`) | `de` |
| `mailto` | Email recipients (comma-separated) | `admin@example.com,web@example.com` |

### Environment Variables (New since v1.4)

| Variable | Description | Default |
|----------|-------------|---------|
| `DEBUG` | Enable debug output | `false` |
| `LOG_FILE` | Set log file location | `/var/log/linkchecker.log` |

### Examples

**Basic website check:**
```bash
./linkchecker.sh https://example.com - en webmaster@example.com
```

**WordPress site with admin panel:**
```bash
./linkchecker.sh https://myblog.com https://myblog.com/wp-admin de admin@myblog.com
```

**With custom exclude patterns:**
```bash
./linkchecker.sh --exclude='\.pdf$' --exclude='/api/' https://example.com - en admin@example.com
```

**Debug mode with custom log file:**
```bash
DEBUG=true LOG_FILE=/tmp/linkcheck.log ./linkchecker.sh https://example.com - en admin@example.com
```

**Multiple recipients:**
```bash
./linkchecker.sh https://company.com https://company.com/admin en "dev@company.com,manager@company.com"
```

## ⚙️ Configuration

### URL Exclusion Patterns
Add REGEX patterns to exclude specific URLs from checking:

```bash
EXCLUDES=(
    "\/xmlrpc\.php\b"           # Exclude xmlrpc.php files
    "\/wp-admin\/"              # Exclude wp-admin paths  
    "\.pdf$"                    # Exclude PDF files
    "\/api\/"                   # Exclude API endpoints
    "\?.*utm_"                  # Exclude URLs with UTM parameters
)
```

### YouTube Video Checking (New since v1.4)
The script automatically detects and validates YouTube videos:
- **Supported domains**: youtube.com, youtube-nocookie.com, youtu.be, yt.be, and country-specific variants
- **Rate limiting**: Max 30 requests per minute to respect API limits
- **Timeout**: 10 seconds per video check
- **Detection**: Identifies deleted, private, and unavailable videos

### LinkChecker Settings (Enhanced since v1.4)
Configurable parameters via `LINKCHECKER_PARAMS`:
```bash
LINKCHECKER_PARAMS="--recursion-level=-1 --timeout=30 --threads=30"
```

Default settings:
- `--user-agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36..."`
- `--check-extern` (check external links)
- `--recursion-level=-1` (unlimited depth)
- `--timeout=30` (30 second timeout)
- `--threads=30` (30 concurrent threads)

### Debug Mode
Enable detailed logging for troubleshooting:
```bash
DEBUG=true  # Set to false for production
```

## 🕐 CRON Automation (Enhanced since v1.4)

The script is optimized for CRON with silent operation - only errors appear on stderr.

### Daily Check at 2 AM
```bash
0 2 * * * /path/to/linkchecker.sh https://example.com - en admin@example.com
```

### Weekly Check with Custom Log File
```bash
0 3 * * 0 LOG_FILE=/var/log/weekly-linkcheck.log /path/to/linkchecker.sh https://example.com - de admin@example.com
```

### Multiple Sites with Exclude Patterns
```bash
# Check multiple websites with different configurations
0 2 * * * /path/to/linkchecker.sh --exclude='\.pdf$' https://site1.com - en admin@site1.com
0 3 * * * /path/to/linkchecker.sh --exclude='/wp-admin/' https://site2.com - en admin@site2.com
```

### CRON Error Handling
```bash
# Example with error notification
0 2 * * * /path/to/linkchecker.sh https://example.com - en admin@example.com 2>&1 | mail -s "Linkchecker Error" admin@example.com
```

## 📧 Email Report Features (Enhanced since v1.4)

### Report Contents
- **Executive Summary**: Check duration, total URLs, error count, success rate
- **YouTube Statistics**: Video checks performed and errors found
- **Detailed Error Table**: Broken URLs with error types and source pages
- **YouTube Error Section**: Separate section for video availability issues
- **CMS Login Link**: Direct link to content management system (if provided)
- **Professional Styling**: Modern responsive design with improved mobile support
- **Timestamp**: Automatic generation timestamp in footer

### YouTube Error Types
- **Video deleted or unavailable**: HTTP 404 or similar
- **Video is private**: Access restricted
- **Could not check video status**: Network or API timeout

### Sample Email Output
The HTML reports include:
- ✅ Website overview with clickable URL
- 📊 Statistics table with key metrics including YouTube checks
- 🔗 Clickable broken links for easy access
- 🎥 YouTube video error section (when applicable)
- 📱 Mobile-responsive design with improved styling
- 🎨 Professional branding with customizable logo

## 📁 Log Files (Enhanced since v1.4)

Logs are written to `/var/log/linkchecker.log` (configurable via `LOG_FILE`) with:
- **Execution timestamps** with clear session markers
- **Processing statistics** including YouTube checks
- **Error details** (when DEBUG=true)
- **Email delivery confirmation**
- **Rate limiting information** for YouTube API calls
- **Performance metrics** and timing data

### Log Rotation
Recommend setting up logrotate:
```bash
# /etc/logrotate.d/linkchecker
/var/log/linkchecker.log {
    daily
    rotate 30
    compress
    missingok
    notifempty
}
```

## 🛠️ Troubleshooting

### Common Issues

**"linkchecker command not found"**
```bash
# Install linkchecker (default path: /usr/local/bin/linkchecker)
sudo apt-get install linkchecker

# Or install via pip
pip install linkchecker
```

**"curl command not found"** (New since v1.4)
```bash
# Install curl for YouTube checks
sudo apt-get install curl
```

**"sendmail command not found"**
```bash
# Install postfix (provides sendmail command)
sudo apt-get install postfix

# Or install ssmtp (lightweight alternative)
sudo apt-get install ssmtp
```

**"Cannot write to log file"** (Enhanced error handling since v1.4)
```bash
# Create log file with proper permissions
sudo touch /var/log/linkchecker.log
sudo chmod 664 /var/log/linkchecker.log

# Or use custom log file location
LOG_FILE=/home/user/linkchecker.log ./linkchecker.sh https://example.com - en admin@example.com
```

**Emails not sending**
```bash
# Check if postfix is running
sudo systemctl status postfix

# Test postfix configuration
sudo postfix check

# Check mail logs
sudo tail -f /var/log/mail.log

# Test sendmail directly
echo -e "From: test@example.tld\nSubject: Test\nTo: youremail@example.tld\n\nTest message" | sendmail -f test@example.tld youremail@example.tld

# Check mail queue
mailq
```

**YouTube checks timing out**
```bash
# Check network connectivity to YouTube
curl -I "https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=dQw4w9WgXcQ&format=json"

# Increase timeout in script if needed (modify YOUTUBE_OEMBED_TIMEOUT)
```

### Debug Mode (Enhanced since v1.4)
Enable debug mode for detailed troubleshooting:
```bash
# Using command line option
./linkchecker.sh --debug https://example.com - en admin@example.com

# Using environment variable
DEBUG=true ./linkchecker.sh https://example.com - en admin@example.com

# View logs in real-time
tail -f /var/log/linkchecker.log
```

### Version Information
Check your script version:
```bash
./linkchecker.sh --help | grep -i version
```

## 🔄 Version History

### v1.6 (2025-08-01)
- 📧 Switched from `mail` to `sendmail` for email delivery
- 🔧 Fixed duplicate `From:` header issue in email reports
- 🛠️ Improved email header control and formatting

### v1.5 (2025-07-30)
- 📧 Setting proper Reply-To and Return-Path values when sending email
- 🔧 Small refactoring improvements

### v1.4 (2025-07-28)
- ✨ Added YouTube video availability checking
- 🔧 Enhanced command-line argument parsing
- 📊 Improved CRON integration with silent operation
- 🛠️ Better error handling and cleanup procedures
- 📱 Enhanced responsive email design
- ⚙️ Configurable linkchecker parameters
- 🚀 Performance improvements and rate limiting

### v1.0 (2025-07-03)
- 🎉 Initial release
- 🔗 Basic link checking functionality
- 📧 HTML email reporting
- 🌐 Bilingual support (DE/EN)

## 📄 License

No license, no warranties, use however you like.

## 🏆 Acknowledgments

- Built on top of [LinkChecker](https://linkchecker.github.io/linkchecker/) by Bastian Kleineidam
- YouTube validation using YouTube oEmbed API
- Inspired by the need for professional website monitoring tools
- Designed for system administrators and web developers

## 🤝 Contributing

Feel free to submit issues, feature requests, or pull requests. All contributions are welcome!

## 📞 Support

For questions or support, please open an issue on GitHub or contact the maintainer.
