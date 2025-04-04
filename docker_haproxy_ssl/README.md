## Usage

    docker run -v /path/to/haproxy.cfg:/haproxy.cfg -e DOMAIN=example.com -e EMAIL=test@example.com --publish "80:80" --publish "443:443" joelcogen/haproxy_ssl

- `DOMAIN` can contain multiple domains, separated by a comma. DNS must already point to your host for SSL verification to work
- `EMAIL` can be any e-mail where letsencrypt can reach you
- You must expose port 80 for SSL verirication to work

### haproxy.cfg

Look at [haproxy.cfg.example](./haproxy.cfg.example), also available in the container for your convenience.

Some notes:

- `log stdout` is probably what you want to get logs in Docker
- Certificate is created in `/certs/haproxy.pem`
- There's a `haproxy` user and group, from the official haproxy image
- Default error files are in `/usr/local/etc/haproxy/errors/`

### How it works

The entrypoint will generate a new certificate for given domains and start a cron to update every 1st of the month at midnight. Certificates are valid 3 months.
