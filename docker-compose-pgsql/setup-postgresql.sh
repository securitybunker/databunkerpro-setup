#!/bin/sh

echo "Creating postgresql user and databunkerdb database"
PGPASSWORD=$POSTGRES_PASSWORD
psql -U postgres -c "CREATE ROLE $PGSQL_USER NOSUPERUSER LOGIN PASSWORD '$PGSQL_PASSWORD'"
psql -U postgres -c "CREATE ROLE mtenant NOSUPERUSER NOLOGIN"
psql -U postgres -c "GRANT mtenant TO $PGSQL_USER"
psql -U postgres -c "CREATE DATABASE $PGSQL_DATABASE OWNER $PGSQL_USER"
