#!/bin/bash

# Check if 'docker-compose' command exists
if command -v docker-compose &> /dev/null; then
    DC="docker-compose"
# Fallback to 'docker compose' if the plugin is available
elif docker compose version &> /dev/null; then
    DC="docker compose"
else
    echo "Neither 'docker-compose' nor 'docker compose' is available."
    exit 1
fi

echo "Using: $DC"
$DC -f ./docker-compose-pgsql.yml down
$DC -f ./docker-compose-mysql.yml down
$DC -f ./docker-compose-pgsql.yml up -d
