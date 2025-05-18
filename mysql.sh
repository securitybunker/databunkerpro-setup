#!/bin/bash

source .env/mysql.env
docker exec -ti databunkerpro-setup_mysql_1 /bin/bash -c "mysql -u bunkeruser -p$MYSQL_PASSWORD databunkerdb"
