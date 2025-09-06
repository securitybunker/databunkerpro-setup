#!/bin/sh

echo 'creating ./data directory'
mkdir -p data
chmod 777 data
mkdir -p .env

echo 'generating .env/postgresql-postgres.env'
POSTGRES_PASSWORD=`< /dev/urandom LC_CTYPE=C tr -dc '_\*^A-Z-a-z-0-9' | head -c${1:-32};`
echo 'POSTGRES_PASSWORD='$POSTGRES_PASSWORD > .env/postgresql-postgres.env

echo 'generating .env/postgresql.env'
PGSQL_USER_PASSWORD=`< /dev/urandom LC_CTYPE=C tr -dc '_\*^A-Z-a-z-0-9' | head -c${1:-32};`
echo 'PGSQL_DATABASE=databunkerdb' > .env/postgresql.env
echo 'PGSQL_USER=bunkeruser' >> .env/postgresql.env
echo 'PGSQL_PASSWORD='$PGSQL_USER_PASSWORD >> .env/postgresql.env

echo 'generating .env/redis.env'
REDIS_USER_PASS=`< /dev/urandom LC_CTYPE=C tr -dc '_\*^A-Z-a-z-0-9' | head -c${1:-32};`
echo 'REDIS_USER_PASS='$REDIS_USER_PASS > .env/redis.env
echo 'REDIS_USER_NAME=default' >> .env/redis.env

echo 'generating .env/databunker.env'
KEY=`< /dev/urandom LC_CTYPE=C tr -dc 'a-f0-9' | head -c${1:-48};`
echo 'DATABUNKER_WRAPPINGKEY='$KEY > .env/databunker.env
echo 'PGSQL_USER_NAME=bunkeruser' >> .env/databunker.env
echo 'PGSQL_USER_PASS='$PGSQL_USER_PASSWORD >> .env/databunker.env
echo 'PGSQL_HOST=postgresql' >> .env/databunker.env
echo 'PGSQL_PORT=5432' >> .env/databunker.env
echo 'REDIS_HOST=redis' >> .env/databunker.env
echo 'REDIS_PORT=6379' >> .env/databunker.env
echo 'REDIS_USER_PASS='$REDIS_USER_PASS >> .env/databunker.env
echo 'REDIS_USER_NAME=default' >> .env/databunker.env

echo 'generating ssl sertificate for postgres server'
rm -rf .env/pg-*
openssl req -new -text -passout pass:abcd -subj /CN=localhost -out .env/pg-server.req -keyout .env/pg-privkey.pem
openssl rsa -in .env/pg-privkey.pem -passin pass:abcd -out .env/pg-server.key
openssl req -x509 -in .env/pg-server.req -text -key .env/pg-server.key -out .env/pg-server.crt

os=$(uname)
if [ "$os" != "Darwin" ]; then
  echo "sudo chown 999:0 .env/pg-*"
  sudo chown 999:0 .env/pg-*
else
  echo "sudo chown 400 .env/pg-*"
  sudo chmod 400 .env/pg-*
fi
