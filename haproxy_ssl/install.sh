#!/bin/bash -e

# Return if not root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

# Check for existing cert
if [ -d "/certs/live/haproxy" ]; then
    echo "Cert already exists:"
    openssl x509 -in /certs/haproxy.pem -text -noout | grep DNS
    read -p "Do you want to overwrite it? (y/n): " OVERWRITE
    if [ "$OVERWRITE" != "y" ]; then
        echo "Exiting"
        exit 0
    fi
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
cp $PWD/haproxy.cfg /etc/haproxy/haproxy.cfg.example

# Add update script to cron
cp $PWD/update.sh /certs/update.sh
(crontab -l 2>/dev/null; echo "0 0 1 * * /certs/update.sh >> /certs/update.log 2>&1") | crontab -
echo ""
echo "Crontab:"
crontab -l

echo ""
echo "Done."
echo "To use base config: cp /etc/haproxy/haproxy.cfg.example /etc/haproxy/haproxy.cfg"
echo "After editing /etc/haproxy/haproxy.cfg, run: systemctl reload haproxy"