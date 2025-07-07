# Automated website link checker with HTML email reporting

A robust Bash script that crawls your website, detects broken links, and sends beautifully formatted HTML email reports. Perfect for automated monitoring via CRON jobs.

## ✨ Features

- **Comprehensive Link Checking**: Crawls internal and external links recursively
- **Professional Email Reports**: HTML emails with responsive design and detailed statistics  
- **Flexible Exclusion System**: REGEX-based URL exclusion patterns
- **Bilingual Support**: German and English report languages
- **CRON-Ready**: Silent operation perfect for automated scheduling
- **Detailed Logging**: Configurable debug levels with comprehensive audit trails
- **UTF-8 Compatible**: Proper encoding for international content
- **Mobile-Friendly**: Responsive email templates that work on all devices

## 📋 Prerequisites

### Required Packages
```bash
# Ubuntu/Debian
sudo apt-get install linkchecker mailutils

# CentOS/RHEL
sudo yum install linkchecker mailx

# macOS (with Homebrew)
brew install linkchecker
```

### System Requirements
- **Bash 4.0+** (for array support)
- **linkchecker** (Python-based link checking tool)
- **mail command** or **ssmtp** (for sending emails)
- **Configured SMTP MTA** (see Email Setup below)

## 📧 Email Setup

The script requires a working SMTP MTA (Mail Transfer Agent) to send email reports. You have two main options:

### Option 1: Postfix (Recommended)

Install and configure Postfix as an SMTP relay:

```bash
# Install Postfix
sudo apt-get install postfix

# Choose "Internet Site" during installation
```

#### Configure Postfix

Edit `/etc/postfix/main.cf`:
```bash
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/saslpass
smtp_sasl_security_options = noanonymous
relayhost = mail.myserver.tld:587  ## in case of SSL, use port 465
myhostname = my.hostname.tld
mydomain = my.domain
smtp_use_tls = yes
```

Create `/etc/postfix/saslpass`:
```bash
mail.myserver.tld		my@mail.username.tld:mypassword
```

Apply configuration:
```bash
# Hash the password file
sudo postmap /etc/postfix/saslpass

# Secure the files
sudo chmod 600 /etc/postfix/saslpass /etc/postfix/saslpass.db

# Restart Postfix
sudo systemctl restart postfix
```

### Option 2: SSMTP (Lightweight Alternative)

Install SSMTP:
```bash
sudo apt-get install ssmtp
```

Configure `/etc/ssmtp/ssmtp.conf`:
```bash
root=myusername
mailhub=my.hostname.tld
hostname=my.hostname.tld
FromLineOverride=YES
UseSTARTTLS=YES
AuthUser=my@mail.username.tld
AuthPass=mypassword
```

#### Modify Script for SSMTP

If using SSMTP, replace the email sending function in the script:

```bash
# Replace this function in send_email_report():
# OLD (mail command):
if sudo -u "$MAIL_SENDER" mail \
    -s "$subject" \
    -a "Content-Type: text/html; charset=UTF-8" \
    -a "Content-Transfer-Encoding: 8bit" \
    -a "From: $MAIL_SENDER_NAME <$MAIL_SENDER>" \
    "$mailto" < "$mail_html" 2>>"$LOG_FILE"; then

# NEW (ssmtp command):
if echo -e "From: $MAIL_SENDER_NAME <$MAIL_SENDER>\nSubject: $subject\nTo: $mailto\nContent-Type: text/html; charset=UTF-8\nContent-Transfer-Encoding: 8bit\n\n$(cat "$mail_html")" | ssmtp -t 2>>"$LOG_FILE"; then
```

### Test Email Configuration

Test your email setup:
```bash
# For Postfix/mail:
echo "Test message" | mail -s "Test Subject" your-email@domain.com

# For SSMTP:
echo -e "From: test@domain.com\nSubject: Test Subject\nTo: your-email@domain.com\n\nTest message" | ssmtp -t
```

## 🚀 Quick Start

### 1. Download the Script
```bash
wget https://raw.githubusercontent.com/yourusername/broken-link-guardian/main/linkchecker.sh
chmod +x linkchecker.sh
```

### 2. Configure Email Settings
Edit the script and modify these variables:
```bash
# Email configuration
MAIL_SENDER="your-email@domain.com"
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
./linkchecker.sh <base_url> <cms_login_url> <language> <mailto>
```

### Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `base_url` | Website URL to check | `https://example.com` |
| `cms_login_url` | CMS login URL (use `-` if none) | `https://example.com/admin` or `-` |
| `language` | Report language (`de` or `en`) | `de` |
| `mailto` | Email recipients (comma-separated) | `admin@example.com,web@example.com` |

### Examples

**Basic website check:**
```bash
./linkchecker.sh https://example.com - en webmaster@example.com
```

**WordPress site with admin panel:**
```bash
./linkchecker.sh https://myblog.com https://myblog.com/wp-admin de admin@myblog.com
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

### Debug Mode
Enable detailed logging for troubleshooting:
```bash
DEBUG=true  # Set to false for production
```

### LinkChecker Settings
The script uses these linkchecker parameters:
- `--user-agent="Your Personal Linkchecker User Agent String/1.0"`
- `--check-extern` (check external links)
- `--recursion-level=10`
- `--timeout=30`
- `--threads=20`

## 🕐 CRON Automation

### Daily Check at 2 AM
```bash
0 2 * * * /path/to/linkchecker.sh https://example.com - en admin@example.com
```

### Weekly Check (Sundays at 3 AM)
```bash
0 3 * * 0 /path/to/linkchecker.sh https://example.com https://example.com/admin de webmaster@example.com
```

### Multiple Sites
```bash
# Check multiple websites
0 2 * * * /path/to/linkchecker.sh https://site1.com - en admin@site1.com
0 3 * * * /path/to/linkchecker.sh https://site2.com - en admin@site2.com
```

## 📧 Email Report Features

### Report Contents
- **Executive Summary**: Check duration, total URLs, error count, success rate
- **Detailed Error Table**: Broken URLs with error types and source pages
- **CMS Login Link**: Direct link to content management system (if provided)
- **Professional Styling**: Century Gothic font, responsive design
- **Mobile Optimization**: Works perfectly on smartphones and tablets

### Sample Email Output
The HTML reports include:
- ✅ Website overview with clickable URL
- 📊 Statistics table with key metrics  
- 🔗 Clickable broken links for easy access
- 📱 Mobile-responsive design
- 🎨 Professional branding and styling

## 📁 Log Files

Logs are written to `/var/log/linkchecker.log` with:
- **Execution timestamps**
- **Processing statistics** 
- **Error details** (when DEBUG=true)
- **Email delivery confirmation**

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
# Install linkchecker
sudo apt-get install linkchecker
```

**"mail command not found"**
```bash
# Install mail utilities
sudo apt-get install mailutils
# OR install ssmtp as alternative
sudo apt-get install ssmtp
```

**"Permission denied" for log file**
```bash
# Create log file with proper permissions
sudo touch /var/log/linkchecker.log
sudo chmod 664 /var/log/linkchecker.log
```

**Emails not sending**
```bash
# Check if postfix is running
sudo systemctl status postfix

# Test postfix configuration
sudo postfix check

# Check mail logs
sudo tail -f /var/log/mail.log

# Test email sending
echo "Test" | mail -s "Test Subject" your-email@domain.com
```

**SSMTP emails not working**
```bash
# Test ssmtp configuration
echo -e "From: test@domain.com\nSubject: Test\nTo: your-email@domain.com\n\nTest message" | ssmtp -t

# Check ssmtp logs
sudo tail -f /var/log/syslog | grep ssmtp
```

**"sudo: unable to resolve host"**
```bash
# Add hostname to /etc/hosts
echo "127.0.0.1 $(hostname)" | sudo tee -a /etc/hosts
```

### Debug Mode
Enable debug mode for detailed troubleshooting:
```bash
# Edit script and set:
DEBUG=true

# Run script to see detailed output
./linkchecker.sh https://example.com - en admin@example.com
```

## 📄 License

No license, no warranties, use however you like.

## 🏆 Acknowledgments

- Built on top of [LinkChecker](https://linkchecker.github.io/linkchecker/) by Bastian Kleineidam
- Inspired by the need for professional website monitoring tools
- Designed for system administrators and web developers
