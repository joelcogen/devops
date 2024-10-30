#!/bin/bash -e

certbot renew --quiet

cat /certs/live/haproxy/fullchain.pem /certs/live/haproxy/privkey.pem > /certs/haproxy.pem
chmod 600 /certs/haproxy.pem

systemctl reload haproxy