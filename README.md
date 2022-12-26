# postgres-backup

This image can be used to run scheduled backups of a Postgres database. It stores the backups locally and gives you the option to also sync backup files to sftp and/or s3 compatible storage.

Backups are stored in `/backup` and the latest backup is linked to `/backup/latest.psql.gz`. It is recommended that you mount /backup as a persistent volume so that the container (or pod) itself remains replaceable.

## tags

```bash
docker pull alexanderczigler/postgres-backup
```

## example

The following yaml snippet shows you how it can look in a docker compose or swarm stack, with sync to Digital Ocean Spaces enabled.

```yaml
postgres-backup:
  image: alexanderczigler/postgres-backup
  environment:
    PG_DB: GO
    PG_HOST: postgres
    PG_PASS: postgrespassword
    PG_PORT: 5432
    PG_USER: postgres
    S3_HOST_BASE: ams3.digitaloceanspaces.com
    S3_HOST_BUCKET: "%(bucket)s.ams3.digitaloceanspaces.com"
    S3_BUCKET: postgres-backup
    S3_DIR: test
    AWS_ACCESS_KEY_ID: ABC123DEF
    AWS_SECRET_ACCESS_KEY: a1b2c3d4e5
```

## environment

    UID                   the user id, default: 65534
    GID                   the group id, default: 65534
    PG_HOST               the host/ip of your postgres database
    PG_PORT               the port number of your postgres database
    PG_USER               the username of your postgres database
    PG_PASS               the password of your postgres database
    PG_DB                 the database name to dump
    EXTRA_OPTS            the extra options to pass to pg_dump command
    CRON_TIME             the interval of cron job to run pg_dump. `0 0 * * *` by default, which is every day at 00:00
    MAX_BACKUPS           the number of backups to keep. When reaching the limit, the old backup will be discarded. No limit by default
    INIT_BACKUP           if set, create a backup when the container starts
    INIT_RESTORE_LATEST   if set, restores latest backup
    NO_CRON               if set, do not start cron. Must be used with INIT_BACKUP to run a single backup and then exit
    S3_BUCKET             the name of the Space where backups are synced
    S3_DIR                the dir where to sync the backup folder
    S3_HOST_BASE:         sometimes called s3 endpoint
    S3_HOST_BUCKET:       bucket url template string
    AWS_ACCESS_KEY_ID     the access key used to connect to the Space
    AWS_SECRET_ACCESS_KEY the secret used to connect to the Space

## Restoring a backup

### Recent

When restoring, I recommend that you exec into the container or pod.

```bash
docker exec -it postgres-backup /bin/bash # docker
kubectl -n my-namespace exec -it postgres-backup /bin/bash # kubernetes

# list backups
cd /backup
ls

# restore a backup
sh /restore.sh /backup/2020-01-01_171901.psql.gz
```

### Older

If you need to fetch a backup that is no longer stored in the running container, you can exec into the container/pod and use s3cmd or sftp to download it. (This, of course, requires that you setup s3 or sftp sync in the first place.)

```bash
kubectl -n my-namespace exec -it postgres /bin/bash
cd /backup

# list remote backups
s3cmd ls s3://my-bucket/postgres/local/backup/

# get a remote backup (called 2020-01-01_133700.psql.gz in this example)
s3cmd get s3://my-bucket/postgres/local/backup/2020-01-01_133700.psql.gz

# restore the backup
sh /restore.sh /backup/2020-01-01_133700.psql.gz
```
