#!/bin/bash

apt -y update
apt -y upgrade
apt install -y docker.io docker-compose certbot

./docker-login.sh
./generate-env-files.sh
./gen-cert.sh srv18.basebunker.com
