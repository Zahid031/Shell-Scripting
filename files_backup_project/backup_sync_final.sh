#!/bin/bash

DEFAULT_CONFIG="/etc/backup_sync.conf"
LOCK_FILE="/tmp/backup_sync.lock"

# Function: print usage
usage() {
    echo "Usage: $0 [-c config_file] [-s \"src1 src2\"] [-d dest] [-e on|off] [--restore]"
    exit 1
}

# Defaults
CONFIG_FILE="$DEFAULT_CONFIG"
CLI_SOURCE_DIRS=""
CLI_DEST_DIR=""
CLI_ENCRYPTION=""
RESTORE_MODE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -c)
            CONFIG_FILE="$2"
            shift 2
            ;;
        -s)
            CLI_SOURCE_DIRS="$2"
            shift 2
            ;;
        -d)
            CLI_DEST_DIR="$2"
            shift 2
            ;;
        -e)
            CLI_ENCRYPTION="$2"
            shift 2
            ;;
        --restore)
            RESTORE_MODE=true
            shift
            ;;
        *)
            usage
            ;;
    esac
done

# Validate config file
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: Config file '$CONFIG_FILE' not found." >&2
    exit 2
fi

# Load config
source "$CONFIG_FILE"

# Apply CLI overrides
if [[ -n "$CLI_SOURCE_DIRS" ]]; then
    SOURCE_DIRS="$CLI_SOURCE_DIRS"
fi

if [[ -n "$CLI_DEST_DIR" ]]; then
    DEST_DIR="$CLI_DEST_DIR"
fi

if [[ -n "$CLI_ENCRYPTION" ]]; then
    if [[ "$CLI_ENCRYPTION" == "on" ]]; then
        ENCRYPTION_ENABLED=true
    elif [[ "$CLI_ENCRYPTION" == "off" ]]; then
        ENCRYPTION_ENABLED=false
    else
        echo "Error: Invalid value for -e. Use 'on' or 'off'." >&2
        exit 3
    fi
fi

# Function: logging
log() {
    local msg="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') : $msg" >> "$LOG_FILE"
}

# Function: send notification email
send_notification_email() {
    if [[ -z "$EMAIL_NOTIFICATION" ]]; then
        log "EMAIL_NOTIFICATION is not set, skipping email."
        return
    fi

    local subject="Backup Completed Successfully"
    local body="
Hello,

Your data backup is completed successfully.

Backup details:
- Source: $SOURCE_DIRS
- Destination: $DEST_DIR
- Remote: $REMOTE_DEST
- Timestamp: $(date '+%Y-%m-%d %H:%M:%S')

You can check the log file at: $LOG_FILE

Regards,
Backup System
"

    printf "Subject: %s\n\n%s\n" "$subject" "$body" | msmtp "$EMAIL_NOTIFICATION"
    log "Notification email sent to $EMAIL_NOTIFICATION"
}

# Log rotation
if [[ -f "$LOG_FILE" ]]; then
    LOG_SIZE=$(stat -c%s "$LOG_FILE")
    if (( LOG_SIZE > MAX_LOG_SIZE )); then
        mv "$LOG_FILE" "$LOG_FILE.old"
        touch "$LOG_FILE"
        chmod 600 "$LOG_FILE"
        log "Log rotated: old log moved to $LOG_FILE.old"
    fi
else
    touch "$LOG_FILE"
    chmod 600 "$LOG_FILE"
fi

log "===== Script started ====="

# Concurrency check
cleanup() {
    rm -f "$LOCK_FILE"
    log "Lock file removed. Script exiting."
}
trap cleanup EXIT

if [[ -f "$LOCK_FILE" ]]; then
    LOCK_PID=$(cat "$LOCK_FILE")
    if ps -p "$LOCK_PID" > /dev/null 2>&1; then
        log "Another instance of backup_sync.sh is already running (PID $LOCK_PID). Exiting."
        echo "Another instance of backup_sync.sh is already running (PID $LOCK_PID)." >&2
        exit 4
    else
        log "Stale lock file found. Removing."
        rm -f "$LOCK_FILE"
    fi
fi

echo $$ > "$LOCK_FILE"
chmod 600 "$LOCK_FILE"
log "Lock acquired with PID $$"

log "Configuration:"
log "  SOURCE_DIRS:       $SOURCE_DIRS"
log "  DEST_DIR:          $DEST_DIR"
log "  REMOTE_DEST:       $REMOTE_DEST"
log "  EXCLUDE_PATTERNS:  $EXCLUDE_PATTERNS"
log "  ENCRYPTION_ENABLED:$ENCRYPTION_ENABLED"
log "  GPG_KEY_ID:        $GPG_KEY_ID"
log "  RETENTION_DAILY:   $RETENTION_DAILY"
log "  RETENTION_WEEKLY:  $RETENTION_WEEKLY"
log "  LOG_FILE:          $LOG_FILE"
log "  MAX_LOG_SIZE:      $MAX_LOG_SIZE"
log "  EMAIL_NOTIFICATION:$EMAIL_NOTIFICATION"
log "  RSYNC_BW_LIMIT:    $RSYNC_BW_LIMIT"
log "  RESTORE_MODE:      $RESTORE_MODE"

TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
WORK_DIR="/tmp/backup_sync_work_$TIMESTAMP"
ARCHIVE_NAME="backup_${TIMESTAMP}.tar.gz"
ARCHIVE_PATH="${DEST_DIR}/${ARCHIVE_NAME}"

# Remote sync function
sync_remote() {
    local file_to_sync
    if [[ "$ENCRYPTION_ENABLED" == true ]]; then
        file_to_sync="${ARCHIVE_PATH}.gpg"
    else
        file_to_sync="${ARCHIVE_PATH}"
    fi

    log "Checking SSH connectivity to $REMOTE_DEST"
    ssh -o BatchMode=yes -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$(echo "$REMOTE_DEST" | cut -d: -f1)" "exit" >>"$LOG_FILE" 2>&1 || {
        log "ERROR: SSH connectivity test failed for $REMOTE_DEST"
        return 1
    }

    log "Starting remote sync to $REMOTE_DEST"
    rsync -avz --bwlimit="$RSYNC_BW_LIMIT" "$file_to_sync" "$REMOTE_DEST" >>"$LOG_FILE" 2>&1 || {
        log "ERROR: rsync to remote destination failed"
        return 1
    }

    log "Remote sync completed successfully"
}

# Backup function
perform_backup() {
    log "Starting backup at $TIMESTAMP"
    mkdir -p "$WORK_DIR"

    EXCLUDE_ARGS=()
    if [[ -n "$EXCLUDE_PATTERNS" ]]; then
        for pattern in $EXCLUDE_PATTERNS; do
            EXCLUDE_ARGS+=(--exclude="$pattern")
        done
    fi

    for src in $SOURCE_DIRS; do
        if [[ -d "$src" ]]; then
            log "Backing up $src"
            rsync -a --delete \
                --bwlimit="$RSYNC_BW_LIMIT" \
                "${EXCLUDE_ARGS[@]}" \
                "$src" "$WORK_DIR" >>"$LOG_FILE" 2>&1 || {
                    log "ERROR: rsync failed for $src"
                    return 1
                }
        else
            log "WARNING: Source directory $src does not exist, skipping"
        fi
    done

    log "Creating archive $ARCHIVE_PATH"
    tar -czf "$ARCHIVE_PATH" -C "$WORK_DIR" . >>"$LOG_FILE" 2>&1 || {
        log "ERROR: Failed to create archive"
        return 1
    }

    if [[ "$ENCRYPTION_ENABLED" == true ]]; then
        log "Encrypting archive using GPG key $GPG_KEY_ID"
        gpg --batch --yes --output "${ARCHIVE_PATH}.gpg" --encrypt --recipient "$GPG_KEY_ID" "$ARCHIVE_PATH" >>"$LOG_FILE" 2>&1 || {
            log "ERROR: GPG encryption failed"
            return 1
        }
        rm -f "$ARCHIVE_PATH"
        log "Encrypted archive created: ${ARCHIVE_PATH}.gpg"
    else
        log "Encryption disabled. Archive created: $ARCHIVE_PATH"
    fi

    rm -rf "$WORK_DIR"
    log "Temporary work directory cleaned: $WORK_DIR"
    log "Backup completed successfully."
}

restore_backup() {
    log "Starting restore mode"

    cd "$DEST_DIR" || {
        log "ERROR: Cannot access $DEST_DIR"
        echo "Cannot access destination directory: $DEST_DIR" >&2
        exit 1
    }

    echo "Available backups:"
    local backups=()
    mapfile -t backups < <(ls -1t backup_*.tar.gz* 2>/dev/null)

    if [[ ${#backups[@]} -eq 0 ]]; then
        echo "No backups found in $DEST_DIR" >&2
        log "No backups found for restoration"
        exit 1
    fi

    for i in "${!backups[@]}"; do
        printf "%3d) %s\n" $((i+1)) "${backups[$i]}"
    done

    echo
    read -p "Select a backup to restore [1-${#backups[@]}]: " choice

    if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#backups[@]} )); then
        echo "Invalid selection" >&2
        log "Invalid restore selection: $choice"
        exit 1
    fi

    local selected_backup="${backups[$((choice-1))]}"
    log "Selected backup: $selected_backup"

    local restore_dir="/tmp/restore_${TIMESTAMP}"
    read -p "Enter restore destination directory (default: $restore_dir): " user_restore_dir
    restore_dir="${user_restore_dir:-$restore_dir}"
    mkdir -p "$restore_dir"

    log "Restoring to $restore_dir"

    if [[ "$selected_backup" == *.gpg ]]; then
        log "Decrypting $selected_backup"
        gpg --output "${restore_dir}/restore.tar.gz" --decrypt "$selected_backup" >>"$LOG_FILE" 2>&1 || {
            log "ERROR: GPG decryption failed"
            echo "GPG decryption failed. Check logs." >&2
            exit 1
        }
        tar -xzf "${restore_dir}/restore.tar.gz" -C "$restore_dir" >>"$LOG_FILE" 2>&1 || {
            log "ERROR: Failed to extract tarball after decryption"
            echo "Failed to extract tarball. Check logs." >&2
            exit 1
        }
        rm -f "${restore_dir}/restore.tar.gz"
    else
        tar -xzf "$selected_backup" -C "$restore_dir" >>"$LOG_FILE" 2>&1 || {
            log "ERROR: Failed to extract unencrypted tarball"
            echo "Failed to extract backup. Check logs." >&2
            exit 1
        }
    fi

    log "Restore completed successfully to $restore_dir"
    echo " Restore completed. Data extracted to: $restore_dir"
}

if [[ "$RESTORE_MODE" == true ]]; then
    restore_backup
else
    if perform_backup && sync_remote; then
        send_notification_email
    else
        log "Backup or sync failed. No notification sent."
    fi
fi

