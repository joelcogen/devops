#!/bin/bash -e

# Set variables
HOST="$1"
CONTAINER_NAME="$2"
BACKUP_DIR="/mnt/backups/$CONTAINER_NAME"
SQLITE_PATH="$3"
BACKUP_COUNT=$4
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
FILENAME="$BACKUP_DIR/backup_$TIMESTAMP.sqlite.gz"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

echo "$CONTAINER_NAME : Starting dump from $HOST"

# Perform PostgreSQL dump
ssh -o StrictHostKeyChecking=accept-new $HOST "docker exec $CONTAINER_NAME cat $SQLITE_PATH | gzip" > $FILENAME
ln -sf $FILENAME "$BACKUP_DIR/latest"

# Remove oldest files, keeping only the 5 most recent
cd "$BACKUP_DIR" || exit
ls -t | tail -n +$((BACKUP_COUNT + 1)) | xargs -r rm --

echo "$CONTAINER_NAME : Saved $(ls -sh $FILENAME)"

# ls -t1 "$BACKUP_DIR"
