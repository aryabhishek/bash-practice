#!/bin/bash

source "config.sh"

echo "Backup started at ${TIMESTAMP}..." >> $LOG_FILE

if [ -d $SRC ]
then
    rsync -av --delete "$SRC/" "$DEST/" >> $LOG_FILE 2>&1

    tar -czf "$BACKUP_FOLDER/$BACKUP_FILE" -C "$DEST" . >> $LOG_FILE 2>&1

    find "$DEST" -name "backup-*.tar.gz" -type f -mtime +7 -exec rm {} \; >> $LOG_FILE 2>&1

    printf "Backup completed succesfully at %s \n\n" "$(date +%Y-%m-%d_%H:%M:%S)" >> $LOG_FILE 2>&1

else 

    echo "Backup Failed!" >> $LOG_FILE 2>&1

fi