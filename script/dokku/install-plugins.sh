#!/bin/bash
set -euo pipefail

if ! command -v dokku >/dev/null 2>&1; then
  echo "ERROR: dokku is not installed on this machine."
  echo
  echo "These scripts must be run on your Dokku droplet (after Part 1 of DOKKU-SETUP.md)."
  echo
  echo "Install Dokku on Ubuntu 22.04:"
  echo "  wget -NP . https://dokku.com/bootstrap.sh"
  echo "  sudo DOKKU_TAG=v0.34.8 bash bootstrap.sh"
  echo
  echo "Then complete setup at http://<droplet-ip>/ or run:"
  echo "  dokku domains:set-global dev.ownoutdoors.com"
  echo "  cat ~/.ssh/id_rsa.pub | dokku ssh-keys:add admin"
  exit 1
fi

echo "Installing Dokku plugins..."

sudo dokku plugin:install https://github.com/dokku/dokku-mysql.git mysql
sudo dokku plugin:install https://github.com/dokku/dokku-redis.git redis
sudo dokku plugin:install https://github.com/dokku/dokku-memcached.git memcached
sudo dokku plugin:install https://github.com/dokku/dokku-letsencrypt.git

echo "Dokku plugins installed."
