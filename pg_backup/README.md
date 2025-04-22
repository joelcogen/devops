## Setup

1. Edit the script to adapt `BACKUP_DIR`. Default user and database are both `app`, you may need to change that too.

2. You must have SSH access to the hosts.

3. Make the script executable and try it out:

   ```bash
   chmod +x backup.sh
   ./backup.sh 1.2.3.4 daily 1
   ```

## Usage

```bash
./backup.sh HOSTNAME SUBFOLDER KEEP_COUNT
```

So, given the command `./backup.sh 1.2.3.4 daily 7`, the default script will save the database `app` on host `1.2.3.4` to `/mnt/backups/daily/backup_TIMESTAMP.dump`, and keep the 7 most recent files.

Using another user or database:

```bash
PGUSER=YOUR_USER DB=YOUR_DATABASE ./backup.sh HOSTNAME SUBFOLDER KEEP_COUNT
```

## Adding to cron

`crontab -e` and add something like:

```bash
0 * * * * /home/app/backup.sh 1.2.3.4 production_hourly 24 | /home/app/logger.sh
```

## Daily

`backup-daily.sh` is a small utily script that doesn't actually perform a backup but copies the latest hourly with the purpose of keeping some for a longer time.

Usage:

```bash
./backup-daily.sh SOURCE_FOLDER DESTINATION KEEP_COUNT
```

E.G. in cron:

```bash
30 0 * * * ~/backup-daily.sh production_hourly production_daily 7 | ~/logger.sh
```

## Sqlite

`backup-sqlite.sh` works the same way but streams a gzipped version of an sqlite file.

Usage:

```bash
./backup-sqlite.sh HOSTNAME CONTAINER_NAME SQLITE_FILE_PATH KEEP_COUNT
```

E.G.

```bash
30 0 * * * ./backup-sqlite.sh n8n.myhost.com n8n .n8n/database.sqlite 7 | ~/logger.sh
```
