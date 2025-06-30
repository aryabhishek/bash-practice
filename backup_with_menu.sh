#!/bin/bash

DEFAULT_CONFIG="./config.conf"
CONFIG_FILE="$DEFAULT_CONFIG"

log_start() {
    echo -e "\n==================== Backup Session: $(date +"%Y-%m-%d %H:%M:%S") ====================" | tee -a "$LOG_FILE"
}

log() {
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] [INFO] $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] [ERROR] $1" | tee -a "$LOG_FILE" >&2
}

log_end() {
    echo "--------------------------------------------------" | tee -a "$LOG_FILE"
    echo -e "\n\n" >> "$LOG_FILE"
}

load_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Config file not found: $CONFIG_FILE"
        exit 1
    fi
    
    source "$CONFIG_FILE"
}

perform_backup() {
    load_config
    log_start
    log "Backup process started using config: $CONFIG_FILE"

    if [ -d "$SRC" ]; then
        log "Source directory found: $SRC"
        log "Starting rsync..."

        rsync -av --delete "$SRC/" "$DEST/" >> "$LOG_FILE" 2>&1
        if [ $? -ne 0 ]; then
            log_error "rsync failed!"
            log_end
            return
        fi

        BACKUP_FILE="backup-$(date +"%Y-%m-%d_%H-%M-%S").tar.gz"
        log "Creating compressed archive: $BACKUP_FILE"

        tar -czf "$BACKUP_FOLDER/$BACKUP_FILE" -C "$DEST/" . >> "$LOG_FILE" 2>&1
        if [ $? -ne 0 ]; then
            log_error "Compression failed!"
            log_end
            return
        fi

        log "Archive created successfully."

        log "Cleaning up backups older than $RETENTION_DAYS days..."
        find "$DEST" -name "backup-*.tar.gz" -type f -mtime +$RETENTION_DAYS -exec rm {} \; >> "$LOG_FILE" 2>&1
        log "Old backups cleaned."

        log "Backup completed successfully."

    else
        log_error "Source directory does not exist: $SRC"
    fi

    log_end
}


while true; do
    echo -e "\n============== Backup Automation Menu =============="
    echo "Current Config: $CONFIG_FILE"
    echo "1) Run Backup"
    echo "2) View Logs"
    echo "3) Clean Old Backups"
    echo "4) Change Config File"
    echo "5) View Backup Folder"
    echo "6) Exit"
    echo "===================================================="
    read -rp "Choose an option [1-6]: " choice

    case $choice in
        1)
            perform_backup
            ;;
        2)
            load_config
            echo "===== Backup Logs ====="
            cat "$LOG_FILE"
            ;;
        3)
            load_config
            echo "Cleaning old backups older than $RETENTION_DAYS days..."
            find "$DEST" -name "backup-*.tar.gz" -type f -mtime +$RETENTION_DAYS -exec rm {} \; >> "$LOG_FILE" 2>&1
            echo "Old backups cleaned."
            ;;
        4)
            echo -n "Enter the path to the new config file: "
            read -r new_config
            if [ -f "$new_config" ]; then
                CONFIG_FILE="$new_config"
                echo "Config file switched to: $CONFIG_FILE"
            else
                echo "Config file not found. No changes made."
            fi
            ;;
        5)
            load_config
            echo "Opening backup folder: $DEST"
            ls -lh "$DEST"
            ;;
        6)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid option. Please try again."
            ;;
    esac
done
