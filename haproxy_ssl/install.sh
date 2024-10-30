#!/bin/bash -e

# Return if not root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

# Prompt for DOMAIN and EMAIL
read -p "Enter the domains (comma separated): " DOMAIN
read -p "Enter the e-mail: " EMAIL

# Install
echo "Installing haproxy and certbot..."
apt update -qq
apt install -y -qq haproxy certbot

# Generate
mkdir -p /certs
certbot certonly --standalone -d $DOMAIN --cert-path /certs/fullchain.pem --key-path /certs/privkey.pem -m $EMAIL --agree-tos --non-interactive

# Copy haproxy config
cp $PWD/haproxy.cfg /etc/haproxy/haproxy.cfg

# Add update script to cron
cp $PWD/update.sh /certs/update.sh
echo "0 0 1 * * /certs/update.sh" | crontab -
echo "Crontab:"
crontab -l

echo "Done, now edit /etc/haproxy/haproxy.cfg then run:"
echo "systemctl reload haproxy"