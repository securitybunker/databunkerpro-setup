#!/bin/sh
#
# Generates the .env files for the Oracle docker-compose stack:
#   .env/oracle.env      -> gvenzl/oracle-free (SYS/SYSTEM password + the app schema user)
#   .env/redis.env       -> redis password
#   .env/databunker.env  -> Databunker Pro connection (ORACLE_* + REDIS_*)
#
# gvenzl/oracle-free auto-creates APP_USER as a schema user with CONNECT + RESOURCE
# + unlimited quota in the FREEPDB1 pluggable database — which is exactly what
# Databunker Pro needs, so no separate schema-setup SQL is required.

mkdir -p .env

# Oracle limits passwords to 30 bytes and parses them as identifiers, so use a
# short, letter-initial, alphanumeric value (no long hex, no special characters).
oracle_pw() { printf 'Db%s' "$(< /dev/urandom LC_CTYPE=C tr -dc 'A-Za-z0-9' | head -c24)"; }

APP_USER_PASSWORD=$(oracle_pw)
ORACLE_PASSWORD=$(oracle_pw)
REDIS_USER_PASS=$(< /dev/urandom LC_CTYPE=C tr -dc '_A-Za-z0-9' | head -c32)
WRAPPINGKEY=$(< /dev/urandom LC_CTYPE=C tr -dc 'a-f0-9' | head -c48)

echo 'generating .env/oracle.env'
{
  echo "ORACLE_PASSWORD=$ORACLE_PASSWORD"
  echo "APP_USER=bunkeruser"
  echo "APP_USER_PASSWORD=$APP_USER_PASSWORD"
} > .env/oracle.env

echo 'generating .env/redis.env'
{
  echo "REDIS_USER_PASS=$REDIS_USER_PASS"
  echo "REDIS_USER_NAME=default"
} > .env/redis.env

echo 'generating .env/databunker.env'
{
  echo "DATABUNKER_WRAPPINGKEY=$WRAPPINGKEY"
  echo "ORACLE_HOST=oracle"
  echo "ORACLE_PORT=1521"
  echo "ORACLE_SERVICE=FREEPDB1"
  echo "ORACLE_USER_NAME=bunkeruser"
  echo "ORACLE_USER_PASS=$APP_USER_PASSWORD"
  echo "# TLS: uncomment the next line and set ORACLE_PORT=2484 after enabling"
  echo "# enable-tls.sh in docker-compose.yml (see README)."
  echo "# ORACLE_SSL_MODE=require"
  echo "REDIS_HOST=redis"
  echo "REDIS_PORT=6379"
  echo "REDIS_USER_PASS=$REDIS_USER_PASS"
  echo "REDIS_USER_NAME=default"
} > .env/databunker.env

echo 'done. next: ./hard-reset.sh (or: docker compose up -d)'
