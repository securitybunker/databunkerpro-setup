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
$DC down
rm -rf data
$DC up -d
