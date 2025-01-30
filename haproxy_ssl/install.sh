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
certbot certonly -n --agree-tos --standalone -d $DOMAIN -m $EMAIL --config-dir /certs --cert-name haproxy
cat /certs/live/haproxy/fullchain.pem /certs/live/haproxy/privkey.pem > /certs/haproxy.pem
chmod 600 /certs/haproxy.pem

# Copy haproxy config
cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.orig
cp $PWD/haproxy.cfg /etc/haproxy/haproxy.cfg

# Add update script to cron
cp $PWD/update.sh /certs/update.sh
(crontab -l 2>/dev/null; echo "0 0 1 * * /certs/update.sh") | crontab -
echo "Crontab:"
crontab -l

echo ""
echo "Done, now edit /etc/haproxy/haproxy.cfg then run:"
echo "systemctl reload haproxy"