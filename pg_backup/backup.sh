#!/bin/bash -e

# Set variables
HOST="$1"
BNAME="$2"
BACKUP_DIR="/mnt/backups/$BNAME"
BACKUP_COUNT=$3
PGUSER=${PGUSER:-app}
DB=${DB:-app}
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
FILENAME="$BACKUP_DIR/backup_$TIMESTAMP.dump"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

echo "$BNAME : Starting dump from $HOST/$DB"

# Perform PostgreSQL dump
ssh -o StrictHostKeyChecking=accept-new $HOST "docker exec \$(docker ps --format \"{{.Names}}\" | grep -E \"postgres|pg\") pg_dump -Fc -U $PGUSER -d $DB" > $FILENAME
ln -sf $FILENAME "$BACKUP_DIR/latest"

# Remove oldest files, keeping only the 5 most recent
cd "$BACKUP_DIR" || exit
ls -t | tail -n +$((BACKUP_COUNT + 1)) | xargs -r rm --

echo "$BNAME : Saved $(ls -sh $FILENAME)"

# ls -t1 "$BACKUP_DIR"
