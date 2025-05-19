#!/bin/bash

CONTAINER=`docker ps --filter "name=$(basename $PWD)" --format "{{.Names}}" | grep mysql`
source .env/mysql.env
docker exec -ti $CONTAINER /bin/bash -c "mysql -u bunkeruser -p$MYSQL_PASSWORD databunkerdb"
