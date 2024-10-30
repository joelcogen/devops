## Setup

1. Edit the script to adapt `BACKUP_DIR`. Default user and database are both `app`, you may need to change that too.

2. I recommend have a `.pgpass` is your home directory. The format is `hostname:port:database:username:password`, one connection per line.
   Alternatively, you can call the script with `PGPASSWORD=*** backup.sh ...`

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

Passing a password (if you skipped step 2):

```bash
PGPASSWORD=YOUR_PASSWORD ./backup.sh HOSTNAME SUBFOLDER KEEP_COUNT
```

## Adding to cron

`crontab -e` and add something like:

```bash
0 2 * * * /home/app/backup.sh 1.2.3.4 production_daily 7 | /home/app/logger.sh
0 * * * * /home/app/backup.sh 1.2.3.4 production_hourly 24 | /home/app/logger.sh
```
