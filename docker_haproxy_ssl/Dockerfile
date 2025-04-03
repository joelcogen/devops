FROM haproxy:alpine

USER root

RUN apk add --no-cache certbot dcron

COPY entrypoint.sh /entrypoint.sh
COPY crontab /crontab
COPY update.sh /certs/update.sh
COPY haproxy.cfg.example /haproxy.cfg.example
RUN mkdir -p /certs
RUN chown -R haproxy:haproxy /certs
RUN chmod +x /entrypoint.sh /certs/update.sh

ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 80
EXPOSE 443

CMD ["haproxy", "-f", "/haproxy.cfg"]