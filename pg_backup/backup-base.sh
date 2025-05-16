#!/bin/bash -e

# Set variables
HOST="$1"
BNAME="$2"
BACKUP_DIR="/mnt/backups/$BNAME"
BACKUP_COUNT=$3
PGUSER=${PGUSER:-app}
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
FILENAME="$BACKUP_DIR/backup_$TIMESTAMP.tar"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

echo "$BNAME : Starting basebackup from $HOST"

# Perform PostgreSQL basebackup
ssh -o StrictHostKeyChecking=accept-new $HOST "docker exec \$(docker ps --format \"{{.Names}}\" | grep -E \"postgres|pg\") sh -c 'rm -rf /tmp/backup && pg_basebackup -D /tmp/backup -Ft -z -P --checkpoint=fast -U $PGUSER && tar -cf - /tmp/backup'" > $FILENAME
ln -sf $FILENAME "$BACKUP_DIR/latest"

# Remove oldest files, keeping only the 5 most recent
cd "$BACKUP_DIR" || exit
ls -t | tail -n +$((BACKUP_COUNT + 1)) | xargs -r rm --

echo "$BNAME : Saved $(ls -sh $FILENAME)"

# ls -t1 "$BACKUP_DIR"
