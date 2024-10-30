#!/bin/bash -e

MEZMO_KEY="REPLACE_ME"
APP_NAME="REPLACE_ME"

# Get the hostname
HOSTNAME=$(hostname)

# Read input line by line
while IFS= read -r line; do
    # Escape double quotes in the line
    escaped_line=$(echo "$line" | sed 's/"/\\"/g')
    
    # Send the log to Mezmo
    curl -s -X POST \
         -H "Content-Type: application/json" \
         -H "apikey: $MEZMO_KEY" \
         -d "{\"lines\": [{\"line\": \"$escaped_line\", \"app\": \"$APP_NAME\", \"level\": \"INFO\"}]}" \
         https://logs.mezmo.com/logs/ingest?hostname=$HOSTNAME
done