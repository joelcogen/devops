```
   _       _      _           _                                           _       _
  (_)     | |    ( )         | |                                         (_)     | |
   _  ___ | | ___|/ ___    __| | _____   _____  _ __  ___   ___  ___ _ __ _ _ __ | |_
  | |/ _ \| |/ _ \ / __|  / _` |/ _ \ \ / / _ \| '_ \/ __| / __|/ __| '__| | '_ \| __|
  | | (_) | |  __/ \__ \ | (_| |  __/\ V / (_) | |_) \__ \ \__ \ (__| |  | | |_) | |_
  | |\___/|_|\___| |___/  \__,_|\___| \_/ \___/| .__/|___/ |___/\___|_|  |_| .__/ \__|
 _/ |                                          | |                         | |
|__/                                           |_|                         |_|
```

A helpful script to maintain servers with:

- an `app` user with no password and public key authentication
- UFW firewall blocking everything except SSH
- Docker and ufw-docker
- Netdata monitoring

Designed for Ubuntu on Hetzner and deployment with Kamal.

## Usage

```bash
chmod +x devops.sh
./devops.sh
```

## Hosts list

Hosts are read from and added to `~/.ssh/config`.

## Main menu

**Connect...**: Connect via SSH as the user or root

**Check status**: Test SSH connection as root and app, UFW status and rules, Docker and ufw-docker status, and Netdata status

**Basic setup**: Enable UFW and create `app` user

**Install Docker**: Install Docker and setup ufw-docker

**Install Netdata agent**: Install and setup Netdata agent

**Open port...**:

- **On subnet**: Open a port on the local `10.0.0.0/24` subnet
- **On internet**: Open a Docker container port to the internet, via ufw-docker

**Test ports**: Test which ports are open on the server

**Add SSH key...**: Add an SSH key to the authorized keys

## Todo

- **Install Netdata dashboard**: Install Netdata, enable web dashboard, add haproxy with HTTP Basic Auth in front of it

## Other resources

- [Pipe to Mezmo logging script](pipe_to_mezmo/README.md)
- [Dump PG keeping X backups](pg_backup/README.md)
- [HAProxy with letsencrypt auto SSL](haproxy_ssl/README.md)
