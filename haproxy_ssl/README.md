## Preparing

Configure your DNS to have a domain pointing to this server's public IP.

Make sure ports 80 and 443 are open.

## Setup

As root:

```bash
./install.sh
```

Edit `/etc/haproxy/haproxy.cfg` then start haproxy:

```bash
systemctl reload haproxy
```

Certificates and the update script are in `/certs`.
