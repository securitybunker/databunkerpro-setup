#!/bin/bash
# Open a sqlplus session on the Oracle container as the Databunker schema user.

source .env/oracle.env

# Resolve the DB container via compose (the project dir name contains "oracle",
# so a plain name-grep would also match the redis/databunkerpro containers).
CID=$(docker compose ps -q oracle 2>/dev/null)
[ -z "$CID" ] && CID=$(docker-compose ps -q oracle 2>/dev/null)
if [ -z "$CID" ]; then
  echo "oracle container is not running (start it with ./hard-reset.sh)"; exit 1
fi

docker exec -ti "$CID" sqlplus "$APP_USER/$APP_USER_PASSWORD@localhost:1521/FREEPDB1"
