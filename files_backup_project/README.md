# File Backup to Remote Server with Encryption, Email Notification, Restore, Decryption

This script automates the process of backing up files and directories to a remote server. It includes features like encryption, email notifications, backup restoration, and log rotation.

## Table of Contents
- [Setup Instructions](#setup-instructions)
  - [1. Configuration File](#1-configuration-file)
  - [2. SSH Key-Based Authentication](#2-ssh-key-based-authentication)
  - [3. GPG Encryption Setup](#3-gpg-encryption-setup)
  - [4. Email Notifications with msmtp](#4-email-notifications-with-msmtp)
  - [5. Log Rotation](#5-log-rotation)
  - [6. Cron Job for Automation](#6-cron-job-for-automation)
- [How to Use the Script](#how-to-use-the-script)
  - [Running a Backup](#running-a-backup)
  - [Restoring a Backup](#restoring-a-backup)
  - [Decryption](#decryption)

## Setup Instructions

### 1. Configuration File

Create a default configuration file at `/etc/backup_sync.conf`. You can override this with the `-c` flag.

```bash
sudo nano /etc/backup_sync.conf
```

Here is an example configuration:

```bash
# Source directories to back up (space-separated)
SOURCE_DIRS="/home/user/documents /home/user/pictures"

# Destination directory for the backup archive
DEST_DIR="/mnt/backups"

# Remote server destination (e.g., user@remote_host:/path/to/backups)
REMOTE_DEST="user@your_remote_server:/backups"

# Patterns to exclude from the backup (space-separated)
EXCLUDE_PATTERNS="*.log .cache"

# Enable or disable encryption (true or false)
ENCRYPTION_ENABLED=true

# GPG key ID for encryption
GPG_KEY_ID="your_gpg_key_id"

# Retention policy
RETENTION_DAILY=7
RETENTION_WEEKLY=4

# Log file path
LOG_FILE="/var/log/backup_sync.log"

# Maximum log file size in bytes
MAX_LOG_SIZE=10485760 # 10MB

# Email address for notifications
EMAIL_NOTIFICATION="your_email@example.com"

# rsync bandwidth limit (in KB/s)
RSYNC_BW_LIMIT=1000
```

### 2. SSH Key-Based Authentication

Set up SSH key-based authentication to allow the script to connect to the remote server without a password.

**On your local machine:**

```bash
ssh-keygen -t rsa -b 4096
```

**Copy the public key to the remote server:**

```bash
ssh-copy-id user@your_remote_server
```

### 3. GPG Encryption Setup

If you want to encrypt your backups, you'll need to set up GPG.

**1. Generate a GPG key:**
Follow the prompts to create a new key.
```bash
gpg --full-generate-key
```

**2. List your GPG keys:**
This command will show you your GPG keys.
```bash
gpg --list-secret-keys --keyid-format LONG
```

**3. Find your Key ID:**
The output will look something like this:
```
sec   rsa4096/XXXXXXXXXXXXXXXX 2025-07-21 [SC]
      YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY
uid                 [ultimate] Your Name <your_email@example.com>
ssb   rsa4096/ZZZZZZZZZZZZZZZZ 2025-07-21 [E]
```
Your GPG Key ID is the long string of characters after `rsa4096/`, which is `XXXXXXXXXXXXXXXX` in this example.

**4. Update the configuration file:**
Open your `backup_sync.conf` file and set the `GPG_KEY_ID` to the key ID you found.
```
GPG_KEY_ID="XXXXXXXXXXXXXXXX"
```

### 4. Email Notifications with msmtp

Install and configure `msmtp` to send email notifications.

**Install msmtp:**

```bash
sudo apt-get update
sudo apt-get install msmtp
```

**Create the configuration file `~/.msmtprc`:**

```
# Set default values for all following accounts.
defaults
auth           on
tls            on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile        ~/.msmtp.log

# Gmail
account        gmail
host           smtp.gmail.com
port           587
from           your_email@gmail.com
user           your_email@gmail.com
password       your_app_password

# Set a default account
account default : gmail
```

**Set the correct permissions for the configuration file:**

```bash
chmod 600 ~/.msmtprc
```

### 5. Log Rotation

The script includes a basic log rotation mechanism. When the log file reaches the `MAX_LOG_SIZE` defined in the configuration, it will be renamed to `backup_sync.log.old`, and a new log file will be created.

### 6. Cron Job for Automation

Schedule the script to run automatically using `cron`. For example, to run the script every day at 2 AM:

```bash
crontab -e
```

Add the following line:

```
0 2 * * * /path/to/your/backup_sync_final.sh
```

## How to Use the Script

### Running a Backup

To run a backup with the default configuration:

```bash
./backup_sync_final.sh
```

**Command-line flags:**

*   `-c <config_file>`: Specify a custom configuration file.
*   `-s "<src1> <src2>"`: Override the source directories.
*   `-d <dest>`: Override the destination directory.
*   `-e <on|off>`: Override the encryption setting.
*   `--restore`: Enter restore mode.

### Restoring a Backup

To restore a backup, use the `--restore` flag:

```bash
./backup_sync_final.sh --restore
```

The script will display a list of available backups. Select the one you want to restore, and provide a destination directory.

### Decryption

If the backup is encrypted, the script will automatically decrypt it during the restore process using the GPG key specified in the configuration file.
