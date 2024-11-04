#!/bin/bash

docker-compose down
rm -rf data
docker-compose up -d
