#!/bin/sh

echo 'creating ./data directory'
mkdir -p data
chmod 777 data
mkdir -p .env

echo 'generating .env/mysql-root.env'
MYSQLROOT=`< /dev/urandom LC_CTYPE=C tr -dc '_\*^A-Z-a-z-0-9' | head -c${1:-32};`
echo 'MYSQL_ROOT_PASSWORD='$MYSQLROOT > .env/mysql-root.env

echo 'generating .env/mysql.env'
MYSQLUSER=`< /dev/urandom LC_CTYPE=C tr -dc '_\*^A-Z-a-z-0-9' | head -c${1:-32};`
echo 'MYSQL_DATABASE=databunkerdb' > .env/mysql.env
echo 'MYSQL_USER=bunkeruser' >> .env/mysql.env
echo 'MYSQL_PASSWORD='$MYSQLUSER >> .env/mysql.env

echo 'generating .env/databunker.env'
KEY=`< /dev/urandom LC_CTYPE=C tr -dc 'a-f0-9' | head -c${1:-48};`
echo 'DATABUNKER_WRAPPINGKEY='$KEY > .env/databunker.env
echo 'MYSQL_USER_NAME=bunkeruser' >> .env/databunker.env
echo 'MYSQL_USER_PASS='$MYSQLUSER >> .env/databunker.env
echo 'MYSQL_SSL_MODE=skip-verify' >> .env/databunker.env
echo 'MYSQL_HOST=mysql' >> .env/databunker.env
echo 'MYSQL_PORT=3306' >> .env/databunker.env
echo 'REDIS_HOST=redis' >> .env/databunker.env

echo 'generating ssl certificate for mysql server with SANs'
rm -rf .env/my-*
# Generate private key
openssl genrsa -out .env/my-server.key 2048
# Generate certificate with SANs using command line arguments
openssl req -new -x509 -key .env/my-server.key -out .env/my-server.crt -days 365 \
    -subj "/C=US/ST=CA/L=San Francisco/O=DataBunkerPro/OU=IT/CN=mysql" \
    -addext "subjectAltName=DNS:mysql,DNS:localhost,DNS:127.0.0.1,IP:127.0.0.1" \
    -addext "basicConstraints=CA:FALSE" \
    -addext "keyUsage=nonRepudiation,digitalSignature,keyEncipherment"
