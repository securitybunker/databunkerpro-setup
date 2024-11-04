#!/bin/bash

DOMAIN=$1

if [[ -z "$DOMAIN" ]]; then
  echo "domain argument is missing"
  exit
fi

apt install -y certbot

certbot certonly -d DOMAIN

#Certificate is saved at: /etc/letsencrypt/live/DOMAIN/fullchain.pem
#Key is saved at:         /etc/letsencrypt/live/DOMAIN/privkey.pem

mkdir -p certs
cp /etc/letsencrypt/live/DOMAIN/fullchain.pem certs/server.cer
cp /etc/letsencrypt/live/DOMAIN/privkey.pem certs/server.key

chmod 444 certs/server.*
chmod 400 .env/pg*
sudo chown 999:0 .env/pg*
