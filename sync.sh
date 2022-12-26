#!/bin/sh

if [ -n "${S3_BUCKET}" ]; then
  echo "Sync archives to S3"
  s3cmd -v sync /backup "s3://${S3_BUCKET}/${S3_DIR}/" --skip-existing
fi

if [ -n "${SSH_HOST}" ]; then
  echo "Sync archives to sftp"
  cd /backup
  find . -name '*.psql.gz' -exec curl -v --insecure -T '{}' "sftp://${SSH_USER}:${SSH_PASS}@${SSH_HOST}/${SSH_PATH}/"'{}' \;
fi
