#!/bin/sh
set -e

[ -z "${PG_HOST}" ] && { echo "=> PG_HOST cannot be empty" ; exit 1; }
[ -z "${PG_PORT}" ] && { echo "=> PG_PORT cannot be empty" ; exit 1; }
[ -z "${PG_USER}" ] && { echo "=> PG_USER cannot be empty" ; exit 1; }
[ -z "${PG_DB}" ] && { echo "=> PG_DB cannot be empty" ; exit 1; }
[ -n "${PG_PASS}" ] && { PG_PASS="PGPASSWORD=\"${PG_PASS}\" "; }

BACKUP_CMD="${PG_PASS} pg_dump -h \"${PG_HOST}\" -p \"${PG_PORT}\" -U \"${PG_USER}\" -d \"${PG_DB}\" ${EXTRA_OPTS} | gzip > /backup/"'${BACKUP_NAME}'

echo "=> Creating backup script"
rm -f /backup.sh
cat <<EOF >> /backup.sh
#!/bin/sh
set -e

MAX_BACKUPS=${MAX_BACKUPS}

BACKUP_NAME=\$(date +\%Y-\%m-\%d_\%H\%M\%S).psql.gz

echo "=> Backup started: \${BACKUP_NAME}"
if ${BACKUP_CMD} ;then
    (cd /backup; rm -f latest.psql.gz; ln -s "\${BACKUP_NAME}" latest.psql.gz)
    echo "   Backup succeeded"
else
    echo "   Backup failed"
    rm -rf "/backup/\${BACKUP_NAME}"
fi

if [ -n "\${MAX_BACKUPS}" ]; then
    while [ \$(ls /backup/*.psql.gz -1 | wc -l) -gt \${MAX_BACKUPS} ];
    do
        BACKUP_TO_BE_DELETED="\$(find /backup -maxdepth 1 -name '*.psql.gz' -print0 | sort -z | head -zn1)"
        echo "   Backup \${BACKUP_TO_BE_DELETED} is deleted"
        rm -rf "\${BACKUP_TO_BE_DELETED}"
    done
fi
echo "=> Backup done"
EOF
chmod +x /backup.sh

echo "=> Creating restore script"
rm -f /restore.sh
cat <<EOF >> /restore.sh
#!/bin/sh
set -e

echo "=> Restore database from \$1"
if cat \$1 | gzip -d | ${PG_PASS} psql -h "${PG_HOST}" -p "${PG_PORT}" -U "${PG_USER}" "${PG_DB}" ;then
    echo "   Restore succeeded"
else
    echo "   Restore failed"
fi
echo "=> Done"
EOF
chmod +x /restore.sh

if [ -n "${INIT_BACKUP}" ]; then
    echo "=> Create a backup on startup"
    /backup.sh
elif [ -n "${INIT_RESTORE_LATEST}" ]; then
    echo "=> Restore latest backup"
    until nc -z "$PG_HOST" "$PG_PORT"
    do
        echo "waiting for database container..."
        sleep 1
    done
    find /backup -maxdepth 1 -name '*.psql.gz' -print0 | sort -z | tail -zn1 | xargs -0 /restore.sh
fi

# Setup s3cmd
echo "host_base = ${S3_HOST_BASE}" >> /root/.s3cfg
echo "host_bucket = ${S3_HOST_BUCKET}" >> /root/.s3cfg

printenv > /etc/environment
crontab /etc/cron.d/crontab
chmod -R 0644 /etc/cron.d
cron

touch /var/log/cron.log
tail -f /var/log/cron.log
