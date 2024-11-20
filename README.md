# databunkerpro-setup

## Copy files to remote server
```
scp * root@157.230.105.185:/root/pro
```

## Prepare server
```
apt -y update
apt -y upgrade
apt install -y docker.io docker-compose certbot
```

## Update DNS records
DNN A for basebunker.com

For example: radwan A 157.230.105.185

## Continue with the setup
```
cd pro
./docker-login.sh
./generate-env-files.sh
./gen-cert.sh radwan.basebunker.com
```

## Start containers
```
hard-reset.sh
```
