#!/bin/bash -e

# Set variables
HOURLY="$1"
BNAME="$2"
SOURCE_DIR="/mnt/backups/$HOURLY"
BACKUP_DIR="/mnt/backups/$BNAME"
BACKUP_COUNT=$3
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
FILENAME="$BACKUP_DIR/backup_$TIMESTAMP.dump"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

cp -L "$SOURCE_DIR/latest" $FILENAME
ln -sf $FILENAME "$BACKUP_DIR/latest"

# Remove oldest files, keeping only the 5 most recent
cd "$BACKUP_DIR" || exit
ls -t | tail -n +$((BACKUP_COUNT + 1)) | xargs -r rm --

echo "$BNAME : Saved $(ls -sh $FILENAME)"

# ls -t1 "$BACKUP_DIR"
