#!/bin/bash -e

certbot renew --quiet

cat /certs/fullchain.pem /certs/privkey.pem > /certs/haproxy.pem
chmod 600 /certs/haproxy.pem

systemctl reload haproxy