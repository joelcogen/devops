#!/bin/sh -e

if [ -z "$DOMAIN" ]; then
    echo "DOMAIN is not set"
    echo "Usage: docker run -v /path/to/haproxy.cfg:/haproxy.cfg -e DOMAIN=example.com -e EMAIL=test@example.com joelcogen/haproxy_ssl"
    exit 1
fi

if [ -z "$EMAIL" ]; then
    echo "EMAIL is not set"
    echo "Usage: docker run -v /path/to/haproxy.cfg:/haproxy.cfg -e DOMAIN=example.com -e EMAIL=test@example.com joelcogen/haproxy_ssl"
    exit 1
fi

if [ ! -f "/haproxy.cfg" ]; then
    echo "/haproxy.cfg does not exist. You need to mount it. Example in /haproxy.cfg.example"
    echo "Usage: docker run -v /path/to/haproxy.cfg:/haproxy.cfg -e DOMAIN=example.com -e EMAIL=test@example.com joelcogen/haproxy_ssl"
    exit 1
fi

certbot certonly -n --agree-tos --standalone -d $DOMAIN -m $EMAIL --config-dir /certs --cert-name haproxy
cat /certs/live/haproxy/fullchain.pem /certs/live/haproxy/privkey.pem > /certs/haproxy.pem
chmod 600 /certs/haproxy.pem

crontab /crontab
crond

exec su -s /bin/sh haproxy -c "exec $*"