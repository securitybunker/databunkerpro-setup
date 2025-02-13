#!/bin/bash

source .env/postgresql-postgres.env
docker exec -ti pro_postgresql_1 /bin/bash -c "PGPASSWORD=$POSTGRES_PASSWORD psql -h 127.0.0.1 -p 5432  -U postgres databunkerdb"
