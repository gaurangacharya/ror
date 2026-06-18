# INSTALL.md — Staging & Production on One Server

Complete install guide: **one Ubuntu server**, **two Dokku apps**, **two domains**, **two git branches**, **one shared Docker network** with explicit container names.

| | Staging | Production |
|---|---|---|
| Dokku app | `staging-ownoutdoorsc` | `production-ownoutdoorsc` |
| Domain | `<STAGING_DOMAIN>` | `<PRODUCTION_DOMAIN>` |
| Git branch | `staging` | `production` |
| Server folder | `/opt/source/staging-ownoutdoorsc` | `/opt/source/production-ownoutdoorsc` |
| Git remote | `dokku-staging` | `dokku-production` |
| Deploy | `git push dokku-staging staging:master` | `git push dokku-production production:master` |

**Repo:** https://github.com/gaurangacharya/ownoutdoorsc.git  
**Stack:** Ruby 3.2.2 · Rails 6.1.7 · Passenger · Sidekiq · Sphinx/Manticore · MySQL · Redis · Memcached · Dokku · Nginx

**Also see:** [STAGING.md](STAGING.md) · [PRODUCTION.md](PRODUCTION.md) · [FRESH-SERVER-SETUP.md](FRESH-SERVER-SETUP.md) · [DEPLOY.md](DEPLOY.md)

---

## Table of contents

1. [Part 1 — Server install steps (one-time)](#part-1--server-install-steps-one-time)
2. [Part 2 — Staging implementation](#part-2--staging-implementation)
3. [Part 3 — Production implementation](#part-3--production-implementation)
4. [Part 4 — Troubleshooting (all commands)](#part-4--troubleshooting-all-commands)

---

# Part 1 — Server install steps (one-time)

Run these **once** on a new Ubuntu 22.04 server before staging or production setup.

**Requirements:** 8 GB RAM recommended (both apps), 2+ vCPU, 80 GB disk, ports **80** and **443** open.

---

## 1.1 Set shared variables

```bash
export SERVER_IP="<YOUR_SERVER_IP>"
export REPO_URL="https://github.com/gaurangacharya/ownoutdoorsc.git"
export ADMIN_EMAIL="<YOUR_EMAIL>"
export NETWORK_NAME="ownoutdoors-internal"
```

| Variable | Description |
|---|---|
| `SERVER_IP` | Public IP of the new server |
| `REPO_URL` | GitHub repository URL |
| `ADMIN_EMAIL` | Email for Let's Encrypt SSL certificates |
| `NETWORK_NAME` | **One shared Docker network** for all staging + production containers |

---

## 1.2 DNS — both domains

Create **A records** before SSL:

```text
<STAGING_DOMAIN>     →  <SERVER_IP>
<PRODUCTION_DOMAIN>  →  <SERVER_IP>
```

| Command | Description |
|---|---|
| `host <STAGING_DOMAIN>` | Verify staging DNS resolves to server IP |
| `host <PRODUCTION_DOMAIN>` | Verify production DNS resolves to server IP |
| `curl -s ifconfig.me` | On server — confirm public IP matches DNS |

```bash
host <STAGING_DOMAIN>
host <PRODUCTION_DOMAIN>
ssh root@$SERVER_IP "curl -s ifconfig.me"
```

---

## 1.3 Prepare Ubuntu server

| Command | Description |
|---|---|
| `apt-get update` | Refresh package lists |
| `apt-get upgrade -y` | Install security updates |
| `ufw allow 80/tcp` | Open HTTP for nginx |
| `ufw allow 443/tcp` | Open HTTPS for nginx |
| `ufw enable` | Enable firewall |

```bash
ssh root@$SERVER_IP

sudo apt-get update
sudo apt-get upgrade -y

sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
sudo ufw status
```

---

## 1.4 Install Dokku

| Command | Description |
|---|---|
| `wget ... bootstrap.sh` | Download Dokku installer |
| `DOKKU_TAG=v0.38.6 bash bootstrap.sh` | Install Dokku v0.38.6 |
| `dokku ssh-keys:add admin` | Allow git push deploy from your workstation |
| `dokku version` | Confirm Dokku installed |

```bash
wget -NP . https://dokku.com/bootstrap.sh
sudo DOKKU_TAG=v0.38.6 bash bootstrap.sh
```

Add SSH key from **workstation**:

```bash
cat ~/.ssh/id_ed25519.pub | sudo dokku ssh-keys:add admin
```

Verify:

```bash
dokku version
sudo systemctl status nginx
```

---

## 1.5 Create two git folders (staging + production branches)

Each environment has its **own folder** tracking its **own branch**.

### Folder structure (after clone)

```text
/opt/source/
├── staging-ownoutdoorsc/          ← git branch: staging
│   ├── script/dokku/
│   │   ├── install-plugins.sh
│   │   ├── setup-app.sh
│   │   ├── post-deploy.sh
│   │   └── finish-setup.sh
│   ├── Dockerfile
│   └── Procfile.production
└── production-ownoutdoorsc/       ← git branch: production
    └── (same repo layout)
```

| Command | Description |
|---|---|
| `git clone -b staging ...` | Clone repo into staging folder on `staging` branch |
| `git clone -b production ...` | Clone repo into production folder on `production` branch |
| `git branch -vv` | Confirm correct branch checked out in each folder |

```bash
sudo mkdir -p /opt/source

sudo git clone -b staging $REPO_URL /opt/source/staging-ownoutdoorsc
cd /opt/source/staging-ownoutdoorsc && sudo git branch -vv

sudo git clone -b production $REPO_URL /opt/source/production-ownoutdoorsc
cd /opt/source/production-ownoutdoorsc && sudo git branch -vv
```

**Later — update scripts on server:**

| Command | Description |
|---|---|
| `git pull origin staging` | Update staging folder from GitHub |
| `git pull origin production` | Update production folder from GitHub |

```bash
cd /opt/source/staging-ownoutdoorsc && sudo git pull origin staging
cd /opt/source/production-ownoutdoorsc && sudo git pull origin production
```

---

## 1.6 Install Dokku plugins (server-wide)

| Command | Description |
|---|---|
| `install-plugins.sh` | Installs mysql, redis, memcached, letsencrypt plugins (once per server) |

```bash
cd /opt/source/staging-ownoutdoorsc
sudo bash script/dokku/install-plugins.sh
```

---

## 1.7 Create shared Docker network

| Command | Description |
|---|---|
| `docker network create ownoutdoors-internal` | Create **one network** shared by staging + production containers |

```bash
sudo docker network create ownoutdoors-internal 2>/dev/null || true
```

### All container names on the network

| App | Container | Network alias | Port | Role |
|---|---|---|---|---|
| Staging | `staging-ownoutdoorsc.web.1` | `staging-ownoutdoorsc.web.1` | 3000 | Passenger web |
| Staging | `staging-ownoutdoorsc.worker.1` | `staging-ownoutdoorsc.worker.1` | — | Sidekiq jobs |
| Staging | `staging-ownoutdoorsc.search.1` | `staging-ownoutdoorsc.search.1` | 3564 | Sphinx search |
| Production | `production-ownoutdoorsc.web.1` | `production-ownoutdoorsc.web.1` | 3000 | Passenger web |
| Production | `production-ownoutdoorsc.worker.1` | `production-ownoutdoorsc.worker.1` | — | Sidekiq jobs |
| Production | `production-ownoutdoorsc.search.1` | `production-ownoutdoorsc.search.1` | 3564 | Sphinx search |

**Connect all 6 containers (run after each deploy):**

| Command | Description |
|---|---|
| `docker network connect --alias <name> ...` | Attach container to network with hostname alias |

```bash
NETWORK_NAME=ownoutdoors-internal

# Staging containers
sudo docker network connect --alias staging-ownoutdoorsc.web.1    $NETWORK_NAME staging-ownoutdoorsc.web.1    2>/dev/null || true
sudo docker network connect --alias staging-ownoutdoorsc.worker.1 $NETWORK_NAME staging-ownoutdoorsc.worker.1 2>/dev/null || true
sudo docker network connect --alias staging-ownoutdoorsc.search.1 $NETWORK_NAME staging-ownoutdoorsc.search.1 2>/dev/null || true

# Production containers
sudo docker network connect --alias production-ownoutdoorsc.web.1    $NETWORK_NAME production-ownoutdoorsc.web.1    2>/dev/null || true
sudo docker network connect --alias production-ownoutdoorsc.worker.1 $NETWORK_NAME production-ownoutdoorsc.worker.1 2>/dev/null || true
sudo docker network connect --alias production-ownoutdoorsc.search.1 $NETWORK_NAME production-ownoutdoorsc.search.1 2>/dev/null || true
```

Verify all containers on network:

```bash
sudo docker network inspect ownoutdoors-internal --format '{{range .Containers}}{{.Name}} {{end}}'
```

---

## Part 1 checklist

```text
[ ] 1.1  Set SERVER_IP, REPO_URL, ADMIN_EMAIL, NETWORK_NAME
[ ] 1.2  DNS A records for staging + production domains
[ ] 1.3  apt update, ufw ports 80/443
[ ] 1.4  Install Dokku + SSH key
[ ] 1.5  git clone staging → /opt/source/staging-ownoutdoorsc
[ ] 1.5  git clone production → /opt/source/production-ownoutdoorsc
[ ] 1.6  install-plugins.sh
[ ] 1.7  docker network create ownoutdoors-internal
```

---

# Part 2 — Staging implementation

---

## 2.1 Staging environment variables

```bash
export APP_NAME="staging-ownoutdoorsc"
export APP_DIR="/opt/source/staging-ownoutdoorsc"
export DOMAIN="<STAGING_DOMAIN>"
export BRANCH="staging"
export SPHINX_HOST="staging-ownoutdoorsc.search.1"
export NETWORK_NAME="ownoutdoors-internal"
```

| Variable | Value | Description |
|---|---|---|
| `APP_NAME` | `staging-ownoutdoorsc` | Dokku application name |
| `APP_DIR` | `/opt/source/staging-ownoutdoorsc` | Git folder on server |
| `DOMAIN` | `<STAGING_DOMAIN>` | Staging website URL |
| `BRANCH` | `staging` | Git branch to deploy |
| `SPHINX_HOST` | `staging-ownoutdoorsc.search.1` | Search container hostname |
| `NETWORK_NAME` | `ownoutdoors-internal` | Shared Docker network |

---

## 2.2 Staging folder & resource structure

```text
/opt/source/staging-ownoutdoorsc/              ← git branch: staging
/var/lib/dokku/data/storage/staging-ownoutdoorsc/
├── sphinx/                                     ← search index data
├── uploads/                                    ← /system/ images (Paperclip)
├── assets/                                     ← compiled assets
└── config/
    ├── config.yml                              ← staging secrets & settings
    └── database.yml                            ← DB config (uses DATABASE_URL)

Dokku services (staging only):
  staging-ownoutdoorsc-db          MySQL
  staging-ownoutdoorsc-redis       Redis
  staging-ownoutdoorsc-memcached   Memcached

Docker containers (staging only):
  staging-ownoutdoorsc.web.1        Passenger :3000
  staging-ownoutdoorsc.worker.1     Sidekiq
  staging-ownoutdoorsc.search.1     Sphinx :3564
```

---

## 2.3 Step 1 — Create app and services

| Command | Description |
|---|---|
| `setup-app.sh` | Creates app, MySQL, Redis, Memcached, storage, scales web/worker/search=1 |

```bash
cd /opt/source/staging-ownoutdoorsc

export APP_NAME=staging-ownoutdoorsc
export DOMAIN=<STAGING_DOMAIN>
export SPHINX_HOST=staging-ownoutdoorsc.search.1

sudo -E bash script/dokku/setup-app.sh
```

Verify:

| Command | Description |
|---|---|
| `dokku mysql:info staging-ownoutdoorsc-db` | Check staging MySQL running |
| `dokku redis:info staging-ownoutdoorsc-redis` | Check staging Redis running |
| `dokku memcached:info staging-ownoutdoorsc-memcached` | Check staging Memcached running |
| `dokku ps:report staging-ownoutdoorsc` | Check web, worker, search all running |

```bash
dokku mysql:info staging-ownoutdoorsc-db
dokku redis:info staging-ownoutdoorsc-redis
dokku memcached:info staging-ownoutdoorsc-memcached
dokku ps:report staging-ownoutdoorsc
```

---

## 2.4 Step 2 — Nginx proxy and Dokku network

| Command | Description |
|---|---|
| `dokku proxy:enable` | Enable nginx reverse proxy for staging |
| `dokku domains:set` | Set staging domain name |
| `dokku ports:set http:80:3000 https:443:3000` | Route 80/443 → Passenger port 3000 |
| `dokku nginx:set x-forwarded-proto-value` | Fix HTTPS redirect loop |
| `dokku network:set initial-network` | Attach app to shared Docker network |

```bash
APP=staging-ownoutdoorsc
DOMAIN=<STAGING_DOMAIN>

sudo dokku proxy:enable $APP
sudo dokku config:unset $APP NO_VHOST 2>/dev/null || true
sudo dokku domains:set $APP $DOMAIN
sudo dokku ports:set $APP http:80:3000 https:443:3000
sudo dokku nginx:set $APP x-forwarded-proto-value '$scheme'
sudo dokku nginx:set $APP proxy-read-timeout 120s
sudo dokku nginx:set $APP proxy-connect-timeout 120s
sudo dokku docker-options:remove $APP deploy "--publish 3000:3000" 2>/dev/null || true
sudo dokku network:set $APP initial-network ownoutdoors-internal
```

---

## 2.5 Step 3 — Mount storage and config files

| Command | Description |
|---|---|
| `storage:mount sphinx` | Persist Sphinx index across restarts |
| `storage:mount uploads` | Persist user-uploaded images |
| `storage:mount assets` | Persist compiled assets |
| `storage:mount config.yml` | Mount staging secrets file into container |

```bash
APP=staging-ownoutdoorsc

sudo mkdir -p /var/lib/dokku/data/storage/$APP/config
sudo chown -R 32767:32767 /var/lib/dokku/data/storage/$APP

dokku storage:mount $APP /var/lib/dokku/data/storage/$APP/sphinx:/opt/app/sphinx
dokku storage:mount $APP /var/lib/dokku/data/storage/$APP/uploads:/opt/app/public/system
dokku storage:mount $APP /var/lib/dokku/data/storage/$APP/assets:/opt/app/public/assets
dokku storage:mount $APP /var/lib/dokku/data/storage/$APP/config/config.yml:/opt/app/config/config.yml
dokku storage:mount $APP /var/lib/dokku/data/storage/$APP/config/database.yml:/opt/app/config/database.yml
```

---

## 2.6 Step 4 — Create staging config.yml

| Command | Description |
|---|---|
| `nano .../config.yml` | Edit staging production settings (domain, SMTP, maps keys) |
| `bundle exec rails secret` | Generate secret_key_base (run twice on workstation) |
| `chown 32767:32767` | Set ownership for container user |

```bash
sudo nano /var/lib/dokku/data/storage/staging-ownoutdoorsc/config/config.yml
```

```yaml
production:
  domain: "<STAGING_DOMAIN>"
  secret_key_base: "<STAGING_rails_secret>"
  app_encryption_key: "<STAGING_rails_secret>"
  sharetribe_mail_from_address: "contact@ownoutdoors.com"
  mail_delivery_method: "smtp"
  smtp_email_address: "smtp.example.com"
  smtp_email_port: "587"
  smtp_email_domain: "<STAGING_DOMAIN>"
  smtp_email_user_name: "SMTP_Injection"
  smtp_email_password: "<SMTP_PASSWORD>"
  smtp_email_tls: true
  google_maps_key: "<BROWSER_MAPS_API_KEY>"
  google_maps_server_key: "<SERVER_GEOCODING_API_KEY>"
  always_use_ssl: true
```

```bash
sudo chown 32767:32767 /var/lib/dokku/data/storage/staging-ownoutdoorsc/config/config.yml
```

---

## 2.7 Step 5 — Create staging database.yml

| Command | Description |
|---|---|
| `tee .../database.yml` | DB config — credentials come from Dokku `DATABASE_URL` |

```bash
sudo tee /var/lib/dokku/data/storage/staging-ownoutdoorsc/config/database.yml > /dev/null << 'EOF'
production:
  adapter: mysql2
  encoding: utf8mb4
  collation: utf8mb4_unicode_ci
  pool: 5
  url: <%= ENV['DATABASE_URL'] %>
EOF

sudo chown 32767:32767 /var/lib/dokku/data/storage/staging-ownoutdoorsc/config/database.yml
```

---

## 2.8 Step 6 — Set staging Dokku environment

| Command | Description |
|---|---|
| `dokku config:set` | Set Rails, Passenger, domain, Sphinx host, secrets for staging |

```bash
dokku config:set staging-ownoutdoorsc \
  RAILS_ENV=production \
  NODE_ENV=production \
  RACK_ENV=production \
  RAILS_SERVE_STATIC_FILES=true \
  RAILS_LOG_TO_STDOUT=true \
  PASSENGER_MIN_INSTANCES=1 \
  PASSENGER_MAX_POOL_SIZE=3 \
  DOMAIN=<STAGING_DOMAIN> \
  SPHINX_HOST=staging-ownoutdoorsc.search.1 \
  SECRET_KEY_BASE=<STAGING_SECRET_KEY_BASE> \
  always_use_ssl=true
```

Optional S3:

```bash
dokku config:set staging-ownoutdoorsc \
  S3_BUCKET_NAME=<STAGING_BUCKET> \
  S3_REGION=us-east-1 \
  AWS_ACCESS_KEY_ID=<KEY> \
  AWS_SECRET_ACCESS_KEY=<SECRET>
```

Verify: `dokku config:show staging-ownoutdoorsc`

---

## 2.9 Step 7 — Deploy staging (workstation)

| Command | Description |
|---|---|
| `git remote add dokku-staging` | Add Dokku deploy remote for staging app |
| `git checkout staging` | Switch to staging branch |
| `git push dokku-staging staging:master` | Deploy staging branch to Dokku (10–20 min first time) |

```bash
cd /path/to/ownoutdoorsc

git remote remove dokku-staging 2>/dev/null || true
git remote add dokku-staging dokku@<SERVER_IP>:staging-ownoutdoorsc

git checkout staging
git pull origin staging
git push dokku-staging staging:master
```

Monitor on server:

```bash
dokku logs staging-ownoutdoorsc --tail
dokku ps:report staging-ownoutdoorsc
```

---

## 2.10 Step 8 — Post-deploy staging setup

| Command | Description |
|---|---|
| `post-deploy.sh` | First-time: db:create, migrate, seed + Sphinx index |
| `finish-setup.sh` | Network connect, nginx fix, search reindex |
| `docker network connect` | Connect staging web/worker/search by container name |
| `nc -zv ...search.1 3564` | Test web can reach search container |
| `rake ts:rebuild` | Rebuild Sphinx index inside search container |

```bash
cd /opt/source/staging-ownoutdoorsc

export APP_NAME=staging-ownoutdoorsc
export DOMAIN=<STAGING_DOMAIN>
export NETWORK_NAME=ownoutdoors-internal

sudo -E bash script/dokku/post-deploy.sh
sudo -E bash script/dokku/finish-setup.sh
```

Connect staging containers (explicit names):

```bash
NETWORK_NAME=ownoutdoors-internal

sudo docker network connect --alias staging-ownoutdoorsc.web.1    $NETWORK_NAME staging-ownoutdoorsc.web.1    2>/dev/null || true
sudo docker network connect --alias staging-ownoutdoorsc.worker.1 $NETWORK_NAME staging-ownoutdoorsc.worker.1 2>/dev/null || true
sudo docker network connect --alias staging-ownoutdoorsc.search.1 $NETWORK_NAME staging-ownoutdoorsc.search.1 2>/dev/null || true

sudo docker exec staging-ownoutdoorsc.web.1 nc -zv staging-ownoutdoorsc.search.1 3564

sudo docker exec staging-ownoutdoorsc.search.1 bash -c \
  'cd /opt/app && RAILS_ENV=production bundle exec rake ts:rebuild'
```

Manual DB (if scripts fail):

```bash
dokku run staging-ownoutdoorsc bundle exec rails db:migrate
dokku run staging-ownoutdoorsc bundle exec rails db:seed
```

---

## 2.11 Step 9 — Staging HTTPS (Let's Encrypt)

| Command | Description |
|---|---|
| `letsencrypt:set email` | Set contact email for SSL cert |
| `letsencrypt:enable` | Request and install SSL certificate for staging domain |

```bash
dokku letsencrypt:set staging-ownoutdoorsc email <ADMIN_EMAIL>
dokku letsencrypt:enable staging-ownoutdoorsc

curl -I https://<STAGING_DOMAIN>/_health
dokku certs:report staging-ownoutdoorsc
```

HTTPS redirect loop fix:

```bash
dokku nginx:set staging-ownoutdoorsc x-forwarded-proto-value '$scheme'
dokku proxy:build-config staging-ownoutdoorsc
```

---

## 2.12 Step 10 — Staging Google Maps API

1. Open [Google Cloud Console → Credentials](https://console.cloud.google.com/google/maps-apis/credentials)
2. Add HTTP referrers for staging domain:

```text
https://<STAGING_DOMAIN>/*
http://<STAGING_DOMAIN>/*
```

3. Set server key IP restriction to `SERVER_IP`
4. Enable: Maps JavaScript API, Places API, Geocoding API

---

## 2.13 Step 11 — Staging images proxy (optional)

If DB copied but uploads missing — proxy images from live site (staging only):

```bash
sudo mkdir -p /home/dokku/staging-ownoutdoorsc/nginx.conf.d
sudo tee /home/dokku/staging-ownoutdoorsc/nginx.conf.d/01-proxy-system-images.conf > /dev/null << 'EOF'
location /system/ {
  proxy_pass https://ownoutdoors.com/system/;
  proxy_set_header Host ownoutdoors.com;
  proxy_ssl_server_name on;
}
EOF
sudo chown dokku:dokku /home/dokku/staging-ownoutdoorsc/nginx.conf.d/01-proxy-system-images.conf
sudo dokku proxy:build-config staging-ownoutdoorsc
```

---

## 2.14 Step 12 — Verify staging

```bash
DOMAIN=<STAGING_DOMAIN>

curl -sI "https://$DOMAIN/_health" | head -3
for cat in water-sports boating motorcycles-scooters-bicycling fishing; do
  code=$(curl -sL -o /dev/null -w "%{http_code}" "https://$DOMAIN/s?category=$cat")
  echo "staging $cat: HTTP $code"
done

dokku ps:report staging-ownoutdoorsc
sudo docker exec staging-ownoutdoorsc.web.1 nc -zv staging-ownoutdoorsc.search.1 3564
sudo docker exec staging-ownoutdoorsc.search.1 mysql -h 127.0.0.1 -P 3564 -e "SELECT COUNT(*) FROM listing_core;"
sudo docker network inspect ownoutdoors-internal --format '{{range .Containers}}{{.Name}} {{end}}'
```

---

## 2.15 Staging — deploy updates (maintenance)

**Workstation:**

```bash
git checkout staging && git pull origin staging
git push origin staging
git push dokku-staging staging:master
```

**Server after deploy:**

```bash
cd /opt/source/staging-ownoutdoorsc && sudo git pull origin staging

export APP_NAME=staging-ownoutdoorsc
export DOMAIN=<STAGING_DOMAIN>
export NETWORK_NAME=ownoutdoors-internal
sudo -E bash script/dokku/finish-setup.sh

dokku run staging-ownoutdoorsc bundle exec rails db:migrate
```

---

## Part 2 checklist

```text
[ ] 2.3  setup-app.sh (staging-ownoutdoorsc)
[ ] 2.4  Nginx proxy + network settings
[ ] 2.5  Mount storage + config files
[ ] 2.6  config.yml (staging secrets)
[ ] 2.7  database.yml
[ ] 2.8  dokku config:set
[ ] 2.9  git push dokku-staging staging:master
[ ] 2.10 post-deploy.sh + finish-setup.sh + network connect
[ ] 2.11 letsencrypt:enable
[ ] 2.12 Google Maps referrers
[ ] 2.14 Verification passed
```

---

# Part 3 — Production implementation

> **WARNING:** Use **production-only** names. Never run staging commands on production. See [PRODUCTION.md](PRODUCTION.md) DO NOT RUN section.

---

## 3.1 Production environment variables

```bash
export APP_NAME="production-ownoutdoorsc"
export APP_DIR="/opt/source/production-ownoutdoorsc"
export DOMAIN="<PRODUCTION_DOMAIN>"
export BRANCH="production"
export SPHINX_HOST="production-ownoutdoorsc.search.1"
export NETWORK_NAME="ownoutdoors-internal"
```

| Variable | Value | Description |
|---|---|---|
| `APP_NAME` | `production-ownoutdoorsc` | Dokku application name |
| `APP_DIR` | `/opt/source/production-ownoutdoorsc` | Git folder on server |
| `DOMAIN` | `<PRODUCTION_DOMAIN>` | Production website URL |
| `BRANCH` | `production` | Git branch to deploy |
| `SPHINX_HOST` | `production-ownoutdoorsc.search.1` | Search container hostname |
| `NETWORK_NAME` | `ownoutdoors-internal` | Shared Docker network (same as staging) |

---

## 3.2 Production folder & resource structure

```text
/opt/source/production-ownoutdoorsc/             ← git branch: production
/var/lib/dokku/data/storage/production-ownoutdoorsc/
├── sphinx/
├── uploads/                                    ← live customer images
├── assets/
└── config/
    ├── config.yml                              ← production secrets (DIFFERENT from staging)
    └── database.yml

Dokku services (production only):
  production-ownoutdoorsc-db
  production-ownoutdoorsc-redis
  production-ownoutdoorsc-memcached

Docker containers (production only):
  production-ownoutdoorsc.web.1
  production-ownoutdoorsc.worker.1
  production-ownoutdoorsc.search.1
```

---

## 3.3 Step 1 — Create app and services

```bash
cd /opt/source/production-ownoutdoorsc

export APP_NAME=production-ownoutdoorsc
export DOMAIN=<PRODUCTION_DOMAIN>
export SPHINX_HOST=production-ownoutdoorsc.search.1

sudo -E bash script/dokku/setup-app.sh
```

Verify:

```bash
dokku mysql:info production-ownoutdoorsc-db
dokku redis:info production-ownoutdoorsc-redis
dokku memcached:info production-ownoutdoorsc-memcached
dokku ps:report production-ownoutdoorsc
```

---

## 3.4 Step 2 — Nginx proxy and Dokku network

```bash
APP=production-ownoutdoorsc
DOMAIN=<PRODUCTION_DOMAIN>

sudo dokku proxy:enable $APP
sudo dokku config:unset $APP NO_VHOST 2>/dev/null || true
sudo dokku domains:set $APP $DOMAIN
sudo dokku ports:set $APP http:80:3000 https:443:3000
sudo dokku nginx:set $APP x-forwarded-proto-value '$scheme'
sudo dokku nginx:set $APP proxy-read-timeout 120s
sudo dokku nginx:set $APP proxy-connect-timeout 120s
sudo dokku docker-options:remove $APP deploy "--publish 3000:3000" 2>/dev/null || true
sudo dokku network:set $APP initial-network ownoutdoors-internal
```

---

## 3.5 Step 3 — Mount storage and config files

```bash
APP=production-ownoutdoorsc

sudo mkdir -p /var/lib/dokku/data/storage/$APP/config
sudo chown -R 32767:32767 /var/lib/dokku/data/storage/$APP

dokku storage:mount $APP /var/lib/dokku/data/storage/$APP/sphinx:/opt/app/sphinx
dokku storage:mount $APP /var/lib/dokku/data/storage/$APP/uploads:/opt/app/public/system
dokku storage:mount $APP /var/lib/dokku/data/storage/$APP/assets:/opt/app/public/assets
dokku storage:mount $APP /var/lib/dokku/data/storage/$APP/config/config.yml:/opt/app/config/config.yml
dokku storage:mount $APP /var/lib/dokku/data/storage/$APP/config/database.yml:/opt/app/config/database.yml
```

---

## 3.6 Step 4 — Create production config.yml

Use **different secrets** than staging.

```bash
sudo nano /var/lib/dokku/data/storage/production-ownoutdoorsc/config/config.yml
```

```yaml
production:
  domain: "<PRODUCTION_DOMAIN>"
  secret_key_base: "<PRODUCTION_rails_secret>"
  app_encryption_key: "<PRODUCTION_rails_secret>"
  sharetribe_mail_from_address: "contact@ownoutdoors.com"
  mail_delivery_method: "smtp"
  smtp_email_address: "smtp.example.com"
  smtp_email_port: "587"
  smtp_email_domain: "<PRODUCTION_DOMAIN>"
  smtp_email_user_name: "SMTP_Injection"
  smtp_email_password: "<SMTP_PASSWORD>"
  smtp_email_tls: true
  google_maps_key: "<BROWSER_MAPS_API_KEY>"
  google_maps_server_key: "<SERVER_GEOCODING_API_KEY>"
  always_use_ssl: true
```

```bash
sudo chown 32767:32767 /var/lib/dokku/data/storage/production-ownoutdoorsc/config/config.yml
```

---

## 3.7 Step 5 — Create production database.yml

```bash
sudo tee /var/lib/dokku/data/storage/production-ownoutdoorsc/config/database.yml > /dev/null << 'EOF'
production:
  adapter: mysql2
  encoding: utf8mb4
  collation: utf8mb4_unicode_ci
  pool: 5
  url: <%= ENV['DATABASE_URL'] %>
EOF

sudo chown 32767:32767 /var/lib/dokku/data/storage/production-ownoutdoorsc/config/database.yml
```

---

## 3.8 Step 6 — Set production Dokku environment

```bash
dokku config:set production-ownoutdoorsc \
  RAILS_ENV=production \
  NODE_ENV=production \
  RACK_ENV=production \
  RAILS_SERVE_STATIC_FILES=true \
  RAILS_LOG_TO_STDOUT=true \
  PASSENGER_MIN_INSTANCES=1 \
  PASSENGER_MAX_POOL_SIZE=3 \
  DOMAIN=<PRODUCTION_DOMAIN> \
  SPHINX_HOST=production-ownoutdoorsc.search.1 \
  SECRET_KEY_BASE=<PRODUCTION_SECRET_KEY_BASE> \
  always_use_ssl=true
```

Verify: `dokku config:show production-ownoutdoorsc`

---

## 3.9 Step 7 — Deploy production (workstation)

```bash
cd /path/to/ownoutdoorsc

git remote remove dokku-production 2>/dev/null || true
git remote add dokku-production dokku@<SERVER_IP>:production-ownoutdoorsc

git checkout production
git pull origin production
git push dokku-production production:master
```

Monitor:

```bash
dokku logs production-ownoutdoorsc --tail
dokku ps:report production-ownoutdoorsc
```

---

## 3.10 Step 8 — Post-deploy production setup

### Option A — Fresh empty production

| Command | Description |
|---|---|
| `post-deploy.sh` | db:create + migrate + **seed** (OK for empty DB only) |

```bash
cd /opt/source/production-ownoutdoorsc

export APP_NAME=production-ownoutdoorsc
export DOMAIN=<PRODUCTION_DOMAIN>
export NETWORK_NAME=ownoutdoors-internal

sudo -E bash script/dokku/post-deploy.sh
sudo -E bash script/dokku/finish-setup.sh
```

### Option B — Migrated live database (DO NOT seed)

| Command | Description |
|---|---|
| `db:migrate` only | Run migrations — **do NOT run post-deploy.sh** (it seeds data) |

```bash
cd /opt/source/production-ownoutdoorsc

export APP_NAME=production-ownoutdoorsc
export DOMAIN=<PRODUCTION_DOMAIN>
export NETWORK_NAME=ownoutdoors-internal

dokku run production-ownoutdoorsc bundle exec rails db:migrate
sudo -E bash script/dokku/finish-setup.sh
```

Connect production containers (explicit names):

```bash
NETWORK_NAME=ownoutdoors-internal

sudo docker network connect --alias production-ownoutdoorsc.web.1    $NETWORK_NAME production-ownoutdoorsc.web.1    2>/dev/null || true
sudo docker network connect --alias production-ownoutdoorsc.worker.1 $NETWORK_NAME production-ownoutdoorsc.worker.1 2>/dev/null || true
sudo docker network connect --alias production-ownoutdoorsc.search.1 $NETWORK_NAME production-ownoutdoorsc.search.1 2>/dev/null || true

sudo docker exec production-ownoutdoorsc.web.1 nc -zv production-ownoutdoorsc.search.1 3564

sudo docker exec production-ownoutdoorsc.search.1 bash -c \
  'cd /opt/app && RAILS_ENV=production bundle exec rake ts:rebuild'
```

---

## 3.11 Step 9 — Migrate data from old server (production)

**Backup old server first.**

| Command | Description |
|---|---|
| `mysql:export` | Export database from old server |
| `mysql:import` | Import into production-ownoutdoorsc-db |
| `tar czf uploads` | Archive uploaded images from old server |

```bash
# OLD server
dokku mysql:export ownoutdoors-db > /tmp/ownoutdoors-db.sql
tar czf /tmp/production-uploads.tar.gz -C /var/lib/dokku/data/storage/ownoutdoors uploads

# NEW server
dokku mysql:import production-ownoutdoorsc-db < /tmp/ownoutdoors-db.sql
dokku run production-ownoutdoorsc bundle exec rails db:migrate

sudo tar xzf /tmp/production-uploads.tar.gz -C /var/lib/dokku/data/storage/production-ownoutdoorsc/
sudo chown -R 32767:32767 /var/lib/dokku/data/storage/production-ownoutdoorsc/uploads
dokku ps:restart production-ownoutdoorsc web
```

---

## 3.12 Step 10 — Production HTTPS

```bash
dokku letsencrypt:set production-ownoutdoorsc email <ADMIN_EMAIL>
dokku letsencrypt:enable production-ownoutdoorsc

curl -I https://<PRODUCTION_DOMAIN>/_health
dokku certs:report production-ownoutdoorsc
```

---

## 3.13 Step 11 — Production Google Maps API

```text
https://<PRODUCTION_DOMAIN>/*
http://<PRODUCTION_DOMAIN>/*
```

---

## 3.14 Step 12 — Verify production

```bash
DOMAIN=<PRODUCTION_DOMAIN>

curl -sI "https://$DOMAIN/_health" | head -3
for cat in water-sports boating motorcycles-scooters-bicycling fishing; do
  code=$(curl -sL -o /dev/null -w "%{http_code}" "https://$DOMAIN/s?category=$cat")
  echo "production $cat: HTTP $code"
done

dokku ps:report production-ownoutdoorsc
sudo docker exec production-ownoutdoorsc.web.1 nc -zv production-ownoutdoorsc.search.1 3564
sudo docker exec production-ownoutdoorsc.search.1 mysql -h 127.0.0.1 -P 3564 -e "SELECT COUNT(*) FROM listing_core;"
sudo docker network inspect ownoutdoors-internal --format '{{range .Containers}}{{.Name}} {{end}}'
```

---

## 3.15 Production — deploy updates (maintenance)

**Workstation:**

```bash
git checkout production && git pull origin production
git push origin production
git push dokku-production production:master
```

**Server after deploy:**

```bash
cd /opt/source/production-ownoutdoorsc && sudo git pull origin production

export APP_NAME=production-ownoutdoorsc
export DOMAIN=<PRODUCTION_DOMAIN>
export NETWORK_NAME=ownoutdoors-internal
sudo -E bash script/dokku/finish-setup.sh

dokku run production-ownoutdoorsc bundle exec rails db:migrate
```

**Backup before risky changes:**

```bash
dokku mysql:export production-ownoutdoorsc-db > production-backup-$(date +%Y%m%d).sql
```

---

## Part 3 checklist

```text
[ ] 3.3  setup-app.sh (production-ownoutdoorsc)
[ ] 3.4  Nginx proxy + network settings
[ ] 3.5  Mount storage + config files
[ ] 3.6  config.yml (production secrets — NOT staging)
[ ] 3.7  database.yml
[ ] 3.8  dokku config:set
[ ] 3.9  git push dokku-production production:master
[ ] 3.10 post-deploy (Option A or B) + network connect
[ ] 3.11 Import DB + uploads if migrating
[ ] 3.12 letsencrypt:enable
[ ] 3.13 Google Maps referrers
[ ] 3.14 Verification passed
[ ] DB backup saved before go-live
```

---

# Part 4 — Troubleshooting (all commands)

Each issue lists **cause**, **fix commands**, and **short description** per command.

---

## 4.1 Search unavailable — staging

**Cause:** `staging-ownoutdoorsc.web.1` cannot reach `staging-ownoutdoorsc.search.1:3564`

| Command | Description |
|---|---|
| `dokku ps:report staging-ownoutdoorsc` | Check web/worker/search containers running |
| `docker network connect ...web.1` | Connect staging web to shared network |
| `docker network connect ...worker.1` | Connect staging worker to shared network |
| `docker network connect ...search.1` | Connect staging search to shared network |
| `nc -zv staging-ownoutdoorsc.search.1 3564` | Test connectivity from web to search |
| `rake ts:rebuild` | Rebuild Sphinx index inside search container |

```bash
dokku ps:report staging-ownoutdoorsc

NETWORK_NAME=ownoutdoors-internal
sudo docker network connect --alias staging-ownoutdoorsc.search.1 $NETWORK_NAME staging-ownoutdoorsc.search.1 2>/dev/null || true
sudo docker network connect --alias staging-ownoutdoorsc.web.1    $NETWORK_NAME staging-ownoutdoorsc.web.1    2>/dev/null || true
sudo docker network connect --alias staging-ownoutdoorsc.worker.1 $NETWORK_NAME staging-ownoutdoorsc.worker.1 2>/dev/null || true

sudo docker exec staging-ownoutdoorsc.web.1 nc -zv staging-ownoutdoorsc.search.1 3564

sudo docker exec staging-ownoutdoorsc.search.1 bash -c \
  'cd /opt/app && RAILS_ENV=production bundle exec rake ts:rebuild'
```

---

## 4.2 Search unavailable — production

**Cause:** `production-ownoutdoorsc.web.1` cannot reach `production-ownoutdoorsc.search.1:3564`

```bash
dokku ps:report production-ownoutdoorsc

NETWORK_NAME=ownoutdoors-internal
sudo docker network connect --alias production-ownoutdoorsc.search.1 $NETWORK_NAME production-ownoutdoorsc.search.1 2>/dev/null || true
sudo docker network connect --alias production-ownoutdoorsc.web.1    $NETWORK_NAME production-ownoutdoorsc.web.1    2>/dev/null || true
sudo docker network connect --alias production-ownoutdoorsc.worker.1 $NETWORK_NAME production-ownoutdoorsc.worker.1 2>/dev/null || true

sudo docker exec production-ownoutdoorsc.web.1 nc -zv production-ownoutdoorsc.search.1 3564

sudo docker exec production-ownoutdoorsc.search.1 bash -c \
  'cd /opt/app && RAILS_ENV=production bundle exec rake ts:rebuild'
```

---

## 4.3 Search unavailable — fix both apps

```bash
NETWORK_NAME=ownoutdoors-internal

sudo docker network connect --alias staging-ownoutdoorsc.search.1 $NETWORK_NAME staging-ownoutdoorsc.search.1 2>/dev/null || true
sudo docker network connect --alias staging-ownoutdoorsc.web.1    $NETWORK_NAME staging-ownoutdoorsc.web.1    2>/dev/null || true
sudo docker network connect --alias staging-ownoutdoorsc.worker.1 $NETWORK_NAME staging-ownoutdoorsc.worker.1 2>/dev/null || true

sudo docker network connect --alias production-ownoutdoorsc.search.1 $NETWORK_NAME production-ownoutdoorsc.search.1 2>/dev/null || true
sudo docker network connect --alias production-ownoutdoorsc.web.1    $NETWORK_NAME production-ownoutdoorsc.web.1    2>/dev/null || true
sudo docker network connect --alias production-ownoutdoorsc.worker.1 $NETWORK_NAME production-ownoutdoorsc.worker.1 2>/dev/null || true
```

| Command | Description |
|---|---|
| All 6 `docker network connect` above | Reconnect every staging + production container to shared network |

---

## 4.4 Homepage 500 — landing page images (staging)

**Cause:** `.jpg` vs `.jpeg` mismatch on category background images

| Command | Description |
|---|---|
| `docker exec ... cp .jpeg .jpg` | Copy jpeg assets to jpg names expected by template |
| `rake assets:precompile` | Recompile assets inside web container |
| `ps:restart ... web` | Restart staging web to load new assets |

```bash
sudo docker exec -u root staging-ownoutdoorsc.web.1 bash -c '
cd /opt/app/app/assets/images
for f in ownOutDoors_category-Water-Sports_BG ownOutDoors_category-Boating_BG \
         ownOutDoors_category-Bicycles-Scooters-Motorcycles_BG ownOutDoors_category-fishing_BG \
         ownOutDoors_infoSectionBG; do
  cp "${f}.jpeg" "${f}.jpg" 2>/dev/null || true
done
chown -R app:app /opt/app/app/assets/images
'
sudo docker exec -u app staging-ownoutdoorsc.web.1 bash -c \
  'cd /opt/app && RAILS_ENV=production bundle exec rake assets:precompile'
dokku ps:restart staging-ownoutdoorsc web
```

---

## 4.5 Homepage 500 — landing page images (production)

Replace `staging-ownoutdoorsc` with `production-ownoutdoorsc` in commands above.

```bash
sudo docker exec -u root production-ownoutdoorsc.web.1 bash -c '
cd /opt/app/app/assets/images
for f in ownOutDoors_category-Water-Sports_BG ownOutDoors_category-Boating_BG \
         ownOutDoors_category-Bicycles-Scooters-Motorcycles_BG ownOutDoors_category-fishing_BG \
         ownOutDoors_infoSectionBG; do
  cp "${f}.jpeg" "${f}.jpg" 2>/dev/null || true
done
chown -R app:app /opt/app/app/assets/images
'
sudo docker exec -u app production-ownoutdoorsc.web.1 bash -c \
  'cd /opt/app && RAILS_ENV=production bundle exec rake assets:precompile'
dokku ps:restart production-ownoutdoorsc web
```

---

## 4.6 Images 404 — `/system/images/...`

**Cause:** Uploads folder empty (DB copied without image files)

| Command | Description |
|---|---|
| `tar czf uploads` | Archive uploads from old server |
| `tar xzf` + `chown 32767:32767` | Extract uploads to correct storage path |
| `ps:restart ... web` | Restart web to serve new files |

**Staging:**

```bash
rsync -avz old-server:/var/lib/dokku/data/storage/ownoutdoors/uploads/ \
  /var/lib/dokku/data/storage/staging-ownoutdoorsc/uploads/
sudo chown -R 32767:32767 /var/lib/dokku/data/storage/staging-ownoutdoorsc/uploads
dokku ps:restart staging-ownoutdoorsc web
```

**Production:**

```bash
rsync -avz old-server:/var/lib/dokku/data/storage/ownoutdoors/uploads/ \
  /var/lib/dokku/data/storage/production-ownoutdoorsc/uploads/
sudo chown -R 32767:32767 /var/lib/dokku/data/storage/production-ownoutdoorsc/uploads
dokku ps:restart production-ownoutdoorsc web
```

---

## 4.7 Google Maps error overlay

**Cause:** API key not authorised for domain

| Step | Description |
|---|---|
| Add HTTP referrers | Add `https://<DOMAIN>/*` in Google Cloud Console |
| Server key IP | Restrict server geocoding key to `SERVER_IP` |
| Enable APIs | Maps JavaScript, Places, Geocoding |
| Wait 2–5 min | Propagation delay before maps work |

---

## 4.8 HTTPS redirect loop

**Cause:** Rails `always_use_ssl` + nginx missing `X-Forwarded-Proto: https`

| Command | Description |
|---|---|
| `nginx:set x-forwarded-proto-value '$scheme'` | Tell Rails request was HTTPS |
| `proxy:build-config` | Rebuild nginx config for the app |

**Staging:**

```bash
dokku nginx:set staging-ownoutdoorsc x-forwarded-proto-value '$scheme'
dokku proxy:build-config staging-ownoutdoorsc
```

**Production:**

```bash
dokku nginx:set production-ownoutdoorsc x-forwarded-proto-value '$scheme'
dokku proxy:build-config production-ownoutdoorsc
```

---

## 4.9 Let's Encrypt fails

**Cause:** DNS not pointing to server yet

| Command | Description |
|---|---|
| Fix DNS A record | Point domain to `SERVER_IP` |
| Wait for propagation | Usually 5–60 minutes |
| `letsencrypt:enable` | Retry SSL certificate request |

```bash
dokku letsencrypt:enable staging-ownoutdoorsc
# or
dokku letsencrypt:enable production-ownoutdoorsc
```

---

## 4.10 Port 3000 conflict — worker/search won't start

**Cause:** `--publish 3000:3000` on all containers; only nginx should bind 80/443

| Command | Description |
|---|---|
| `docker-options:remove ... --publish 3000:3000` | Remove host port binding from app containers |
| `ps:restart` | Restart all processes for the app |

```bash
dokku docker-options:remove staging-ownoutdoorsc deploy "--publish 3000:3000"
dokku ps:restart staging-ownoutdoorsc

dokku docker-options:remove production-ownoutdoorsc deploy "--publish 3000:3000"
dokku ps:restart production-ownoutdoorsc
```

---

## 4.11 NO_VHOST=1 set accidentally

**Cause:** Disables Dokku nginx proxy — site unreachable on port 80/443

| Command | Description |
|---|---|
| `config:unset NO_VHOST` | Remove flag blocking nginx |
| `proxy:enable` | Re-enable nginx proxy |
| `proxy:build-config` | Rebuild nginx configuration |

```bash
dokku config:unset staging-ownoutdoorsc NO_VHOST
dokku proxy:enable staging-ownoutdoorsc
dokku proxy:build-config staging-ownoutdoorsc
```

---

## 4.12 Worker stuck / background jobs not running

**Cause:** Sidekiq worker down or Redis unreachable

| Command | Description |
|---|---|
| `logs -t -p worker` | View Sidekiq worker logs |
| `ps:restart ... worker` | Restart worker only (web stays up) |
| `redis:info` | Check Redis service status |
| `config:get REDIS_URL` | Verify Redis URL is set |

**Staging:**

```bash
dokku logs staging-ownoutdoorsc -t -p worker
dokku ps:restart staging-ownoutdoorsc worker
dokku redis:info staging-ownoutdoorsc-redis
```

**Production:**

```bash
dokku logs production-ownoutdoorsc -t -p worker
dokku ps:restart production-ownoutdoorsc worker
dokku redis:info production-ownoutdoorsc-redis
```

---

## 4.13 Deploy build fails

**Cause:** Gem/asset errors, out of disk, out of memory

| Command | Description |
|---|---|
| `dokku logs --build <app>` | View Docker build log for failed deploy |
| `df -h` | Check disk space |
| `free -h` | Check available RAM |

```bash
dokku logs staging-ownoutdoorsc --build
dokku logs production-ownoutdoorsc --build
df -h
free -h
```

---

## 4.14 Rollback after bad deploy

| Command | Description |
|---|---|
| `ps:restore <app>` | Roll back to previous Docker release |
| `finish-setup.sh` | Reconnect network + reindex search after rollback |

```bash
dokku ps:restore production-ownoutdoorsc

cd /opt/source/production-ownoutdoorsc
export APP_NAME=production-ownoutdoorsc
export DOMAIN=<PRODUCTION_DOMAIN>
sudo -E bash script/dokku/finish-setup.sh
```

---

## 4.15 Useful diagnostic commands (both apps)

| Command | Description |
|---|---|
| `dokku apps:list` | List all Dokku apps on server |
| `dokku ps:report staging-ownoutdoorsc` | Process status for staging |
| `dokku ps:report production-ownoutdoorsc` | Process status for production |
| `dokku logs <app> -t -p web` | Live web server logs |
| `dokku logs <app> -t -p worker` | Live Sidekiq worker logs |
| `dokku logs <app> -t -p search` | Live search container logs |
| `dokku enter <app> web` | Shell into web container |
| `dokku mysql:connect <app>-db` | MySQL console |
| `dokku redis:connect <app>-redis` | Redis CLI |
| `dokku nginx:show-config <app>` | View nginx vhost config |
| `dokku certs:report <app>` | SSL certificate status |
| `docker network inspect ownoutdoors-internal` | Show all containers on shared network |
| `docker exec <app>.search.1 mysql -h 127.0.0.1 -P 3564 -e "SHOW TABLES;"` | List Sphinx index tables |
| `docker exec <app>.search.1 ... SELECT COUNT(*) FROM listing_core` | Count indexed listings |

---

## Full install order (quick reference)

```text
PART 1 — Server (once)
  1.1 Variables
  1.2 DNS both domains
  1.3 Prepare Ubuntu
  1.4 Install Dokku + SSH key
  1.5 Clone staging + production git folders
  1.6 install-plugins.sh
  1.7 docker network create ownoutdoors-internal

PART 2 — Staging
  2.3–2.14 All staging steps
  Connect: staging-ownoutdoorsc.web.1, .worker.1, .search.1

PART 3 — Production
  3.3–3.14 All production steps
  Connect: production-ownoutdoorsc.web.1, .worker.1, .search.1

PART 4 — If anything breaks, see troubleshooting above
```

---

## Related files

| File | Description |
|---|---|
| [INSTALL.md](INSTALL.md) | This guide — complete install |
| [STAGING.md](STAGING.md) | Staging-only quick reference |
| [PRODUCTION.md](PRODUCTION.md) | Production-only + DO NOT RUN warnings |
| [FRESH-SERVER-SETUP.md](FRESH-SERVER-SETUP.md) | Original single-app setup reference |
| [DEPLOY.md](DEPLOY.md) | Git deploy workflow |
| `script/dokku/install-plugins.sh` | Install mysql, redis, memcached, letsencrypt |
| `script/dokku/setup-app.sh` | Create app + services (`APP_NAME=...`) |
| `script/dokku/post-deploy.sh` | DB migrate/seed + initial index |
| `script/dokku/finish-setup.sh` | Network connect + search reindex |
| `Procfile.production` | web, worker, search process definitions |
