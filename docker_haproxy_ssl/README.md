## Usage

    docker run -v /path/to/haproxy.cfg:/haproxy.cfg -v ./certs:/certs -e DOMAIN=example.com -e EMAIL=test@example.com --publish "80:80" --publish "443:443" --restart=always joelcogen/haproxy_ssl

- `DOMAIN` can contain multiple domains, separated by a comma. DNS must already point to your host for SSL verification to work
- `EMAIL` can be any e-mail where letsencrypt can reach you
- You must expose port 80 for SSL verirication to work
- I recommend mounting `/certs` to a host folder so certificates are kept between deployments

### haproxy.cfg

Look at [haproxy.cfg.example](./haproxy.cfg.example), also available in the container for your convenience.

Some notes:

- `log stdout` is probably what you want to get logs in Docker
- Certificate is created in `/certs/haproxy.pem`
- There's a `haproxy` user and group, from the official haproxy image
- Default error files are in `/usr/local/etc/haproxy/errors/`

### How it works

The entrypoint will generate a new certificate for given domains.

Container forces restart every 45 days to get fresh certificates. You must have `--restart=always` or `unless-stopped`.
