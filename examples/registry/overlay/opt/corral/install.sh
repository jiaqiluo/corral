#!/bin/bash
set -ex

# Install the user's public key in case they need to debug an issue
echo "$CORRAL_corral_user_public_key" >> /$(whoami)/.ssh/authorized_keys

apt update -y

# apt update will hold the lock for about 30 seconds,
# so we use snap to install other packages first
snap refresh
snap install --classic go
snap install yq

apt install -y apache2-utils certbot docker-compose docker-buildx make

# check all components
go version
make -v
yq --version
docker version
docker buildx version

# generate the certs
certbot certonly --standalone -d "$CORRAL_registry_host" -m xegom53748@xegom53748.com  --non-interactive  --agree-tos
mkdir -p /etc/nginx/certs
cp /etc/letsencrypt/live/"$CORRAL_registry_host"/fullchain.pem /etc/nginx/certs/fullchain.pem
cp /etc/letsencrypt/live/"$CORRAL_registry_host"/privkey.pem /etc/nginx/certs/privkey.pem

# corral variables are available as environment variables with the prefix `CORRAL_`
sed -i "s/HOSTNAME/$CORRAL_registry_host/g" /etc/nginx/nginx.conf

cd /opt/corral
docker-compose up -d
