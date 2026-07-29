#!/bin/bash

CONTAINER=`docker ps --filter "name=$(basename $PWD)" --format "{{.Names}}" | grep -v redis | grep databunkerpro`
docker logs -f $CONTAINER
