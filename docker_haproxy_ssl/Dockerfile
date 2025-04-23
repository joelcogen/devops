FROM haproxy:alpine

USER root

RUN apk add --no-cache certbot coreutils

COPY entrypoint.sh /entrypoint.sh
COPY haproxy.cfg.example /haproxy.cfg.example
RUN mkdir -p /certs
RUN chown -R haproxy:haproxy /certs
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 80
EXPOSE 443

# 3888000 = 45 days
CMD ["timeout", "--foreground", "3888000", "haproxy", "-f", "/haproxy.cfg"]