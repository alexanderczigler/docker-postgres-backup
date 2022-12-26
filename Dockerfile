FROM alexanderczigler/cron

RUN mkdir /backup

# Prepare apt
RUN apt-get update && apt-get install -y gnupg

# Install s3cmd from backports
RUN sh -c 'echo "deb http://deb.debian.org/debian buster-backports main" >> /etc/apt/sources.list.d/backports.list'
RUN apt-get update && apt-get install -y s3cmd/buster-backports

# Install deps
RUN apt-get update && \
    apt-get -y install tzdata openssl wget lsb-release netcat curl

# Install PostgreSQL 11
RUN apt-get update && \
    apt-get -y install postgresql postgresql-contrib

ENV UID=65534 \
    GID=65534 \
    PG_DB="postgres" \
    PG_HOST="postgres" \
    PG_PORT="5432" \
    PG_USER="root" \
    PG_PASS="" \
    EXTRA_OPTS="--inserts"

ADD run.sh /run.sh

COPY crontab /etc/cron.d/crontab

COPY sync.sh /sync.sh
COPY .s3cfg /root/.s3cfg

VOLUME ["/backup"]
CMD ["/run.sh"]
