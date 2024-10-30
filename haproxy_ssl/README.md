## Setup

As root:

```bash
./install.sh
```

Edit `/etc/haproxy/haproxy.cfg` then reload haproxy:

```bash
systemctl reload haproxy
```

Certificates and the update script are in `/certs`.
