#!/bin/bash

CONTAINER=`docker ps --filter "name=$(basename $PWD)" --format "{{.Names}}" | grep postgresql`
source .env/postgresql-postgres.env
docker exec -ti $CONTAINER /bin/bash -c "PGPASSWORD=$POSTGRES_PASSWORD psql -h 127.0.0.1 -p 5432  -U postgres databunkerdb"
