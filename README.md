# databunkerpro-setup

## Copy files to remote server
```
scp * root@srv18.basebunker.com:/root/pro
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
./gen-cert.sh srv18.basebunker.com
```

## Start containers
```
hard-reset.sh
```

## Troubleshoting
Make sure the operating system is correct
```
docker pull registry.databunker.org/databunkerpro:latest
```
