#!/bin/bash -e

systemctl stop haproxy

certbot renew --quiet --config-dir /certs

cat /certs/live/haproxy/fullchain.pem /certs/live/haproxy/privkey.pem > /certs/haproxy.pem
chmod 600 /certs/haproxy.pem

systemctl start haproxy