#!/bin/bash -e

# Set variables
HOST="$1"
BACKUP_DIR="/mnt/backups/$2"
BACKUP_COUNT=$3
PGUSER=${PGUSER:-app}
DB=${DB:-app}

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Generate timestamp for the backup file
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

echo "$HOST > $BACKUP_DIR/backup_$TIMESTAMP.dump"

# Perform PostgreSQL dump
pg_dump -Fc -h "$HOST" -U $PGUSER -d $DB > "$BACKUP_DIR/backup_$TIMESTAMP.dump"

# Remove oldest files, keeping only the 5 most recent
cd "$BACKUP_DIR" || exit
ls -t | tail -n +$((BACKUP_COUNT + 1)) | xargs -r rm --

# ls -t1 "$BACKUP_DIR"