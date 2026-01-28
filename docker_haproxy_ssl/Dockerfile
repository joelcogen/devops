FROM haproxy:alpine

# root block
USER root

RUN apk add --no-cache certbot coreutils

COPY entrypoint.sh /entrypoint.sh
COPY haproxy.cfg.example /haproxy.cfg.example
COPY errors /usr/local/etc/haproxy/errors
RUN mkdir -p /certs
RUN chown -R haproxy:haproxy /certs
RUN chmod +x /entrypoint.sh
# end root block

USER haproxy

ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 80
EXPOSE 443

# 2419200 = 28 days. autorenew is 30 so this gives us 2 days margin in the worst case
CMD ["timeout", "--foreground", "2419200", "haproxy", "-f", "/haproxy.cfg"]
