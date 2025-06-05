#!/bin/bash

apt -y update
apt -y upgrade
apt install -y docker.io docker-compose certbot

./generate-env-files.sh
./gen-cert.sh srv18.basebunker.com
