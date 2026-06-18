# Fresh Server Setup Guide — OwnOutdoors (Dokku)

Complete step-by-step guide to deploy **ror-ownoutdoorsc** (or any OwnOutdoors Dokku instance) on a **new Ubuntu server** so the site runs correctly: HTTPS, search, images, and maps.

**Stack:** Ruby 3.2.2 · Rails 6.1.7 · Passenger · Sidekiq · Thinking Sphinx (Manticore) · MySQL · Redis · Memcached · Dokku · Nginx

---

## Table of contents

1. [Prerequisites](#1-prerequisites)
2. [Install Dokku](#2-install-dokku)
3. [Install plugins & create app](#3-install-plugins--create-app)
4. [Configure services & storage](#4-configure-services--storage)
5. [Configure secrets & config files](#5-configure-secrets--config-files)
6. [Deploy the application](#6-deploy-the-application)
7. [Post-deploy setup (required)](#7-post-deploy-setup-required)
8. [HTTPS & domain (Let's Encrypt)](#8-https--domain-lets-encrypt)
9. [Search (Sphinx) setup](#9-search-sphinx-setup)
10. [Images & uploads](#10-images--uploads)
11. [Google Maps API](#11-google-maps-api)
12. [Verification checklist](#12-verification-checklist)
13. [Day-to-day commands](#13-day-to-day-commands)
14. [Troubleshooting](#14-troubleshooting)

---

## 1. Prerequisites

### Server

| Item | Requirement |
|---|---|
| OS | Ubuntu 22.04 LTS |
| RAM | **4 GB minimum** (2 GB works but asset compile is slow) |
| CPU | 2 vCPU recommended |
| Disk | 40 GB+ (uploads and DB grow over time) |
| Ports | **80** and **443** open in firewall |

### DNS (before SSL)

Create an **A record** pointing your domain to the server public IP **before** enabling Let's Encrypt:

```
ror-ownoutdoorsc.agiletechnologies.in  →  <SERVER_PUBLIC_IP>
```

Verify:

```bash
host ror-ownoutdoorsc.agiletechnologies.in
curl -s ifconfig.me   # should match DNS
```

### Local machine

- Git access to this repository
- SSH key added to the server
- `git push` access to Dokku (`dokku@<server-ip>:ownoutdoors`)

---

## 2. Install Dokku

SSH into the fresh server as root or sudo user:

```bash
wget -NP . https://dokku.com/bootstrap.sh
sudo DOKKU_TAG=v0.38.6 bash bootstrap.sh
```

Add your SSH key (from your workstation):

```bash
cat ~/.ssh/id_ed25519.pub | sudo dokku ssh-keys:add admin
```

Optional global hostname (not required if you set per-app domain later):

```bash
sudo dokku domains:set-global <your-server-ip>
```

Verify:

```bash
dokku version
sudo systemctl status nginx
```

---

## 3. Install plugins & create app

Clone the repo on the server (or copy the setup scripts):

```bash
git clone <repo-url> /opt/source/ror-ownoutdoorsc
cd /opt/source/ror-ownoutdoorsc
```

Install Dokku plugins:

```bash
sudo bash script/dokku/install-plugins.sh
```

Run the automated app provisioner (customise domain if needed):

```bash
export APP_NAME=ownoutdoors
export DOMAIN=ror-ownoutdoorsc.agiletechnologies.in
export SPHINX_HOST=ownoutdoors.search.1

sudo -E bash script/dokku/setup-app.sh
```

Then apply **critical settings** that `setup-app.sh` does not cover:

```bash
APP=ownoutdoors

# Enable nginx reverse proxy (required — do NOT leave NO_VHOST=1)
sudo dokku proxy:enable $APP
sudo dokku config:unset $APP NO_VHOST 2>/dev/null || true

# Set domain and nginx ports
sudo dokku domains:set $APP $DOMAIN
sudo dokku ports:set $APP http:80:3000 https:443:3000

# Fix HTTPS redirect loop behind nginx proxy
sudo dokku nginx:set $APP x-forwarded-proto-value '$scheme'
sudo dokku nginx:set $APP proxy-read-timeout 120s
sudo dokku nginx:set $APP proxy-connect-timeout 120s

# Remove host port publish from ALL containers (only nginx should bind 80/443)
sudo dokku docker-options:remove $APP deploy "--publish 3000:3000" 2>/dev/null || true

# Shared Docker network so web/worker can reach search.1 by hostname
sudo docker network create ownoutdoors-internal 2>/dev/null || true
sudo dokku network:set $APP initial-network ownoutdoors-internal
```

---

## 4. Configure services & storage

`setup-app.sh` creates and links MySQL, Redis, and Memcached. Verify:

```bash
dokku mysql:info ownoutdoors-db
dokku redis:info ownoutdoors-redis
dokku memcached:info ownoutdoors-memcached
```

### Persistent storage

Data must survive container restarts:

```bash
APP=ownoutdoors
sudo mkdir -p /var/lib/dokku/data/storage/$APP/{sphinx,uploads,assets,config}
sudo chown -R 32767:32767 /var/lib/dokku/data/storage/$APP

dokku storage:mount $APP /var/lib/dokku/data/storage/$APP/sphinx:/opt/app/sphinx
dokku storage:mount $APP /var/lib/dokku/data/storage/$APP/uploads:/opt/app/public/system
dokku storage:mount $APP /var/lib/dokku/data/storage/$APP/assets:/opt/app/public/assets
dokku storage:mount $APP /var/lib/dokku/data/storage/$APP/config/config.yml:/opt/app/config/config.yml
dokku storage:mount $APP /var/lib/dokku/data/storage/$APP/config/database.yml:/opt/app/config/database.yml
```

---

## 5. Configure secrets & config files

### 5.1 `config.yml` (production settings)

Create on the server:

```bash
sudo nano /var/lib/dokku/data/storage/ownoutdoors/config/config.yml
```

Example (adjust values for your environment):

```yaml
production:
  domain: "ror-ownoutdoorsc.agiletechnologies.in"
  secret_key_base: '<run: rails secret>'
  app_encryption_key: '<run: rails secret>'
  sharetribe_mail_from_address: "contact@ownoutdoors.com"
  mail_delivery_method: "smtp"
  smtp_email_address: "smtp.example.com"
  smtp_email_port: "587"
  smtp_email_domain: "ror-ownoutdoorsc.agiletechnologies.in"
  smtp_email_user_name: "SMTP_Injection"
  smtp_email_password: "<password>"
  smtp_email_tls: true
  google_maps_key: '<browser-maps-api-key>'
  google_maps_server_key: '<server-geocoding-api-key>'
  always_use_ssl: true
  # ... other production keys (chargebee, fareharbor, sentry, etc.)
```

### 5.2 `database.yml`

Dokku MySQL plugin sets `DATABASE_URL` automatically. You can also mount a static file:

```bash
sudo tee /var/lib/dokku/data/storage/ownoutdoors/config/database.yml > /dev/null << 'EOF'
production:
  adapter: mysql2
  encoding: utf8mb4
  collation: utf8mb4_unicode_ci
  pool: 5
  url: <%= ENV['DATABASE_URL'] %>
EOF
sudo chown 32767:32767 /var/lib/dokku/data/storage/ownoutdoors/config/database.yml
```

### 5.3 Dokku environment variables

```bash
dokku config:set ownoutdoors \
  RAILS_ENV=production \
  NODE_ENV=production \
  RACK_ENV=production \
  RAILS_SERVE_STATIC_FILES=true \
  RAILS_LOG_TO_STDOUT=true \
  PASSENGER_MIN_INSTANCES=1 \
  PASSENGER_MAX_POOL_SIZE=3 \
  DOMAIN=ror-ownoutdoorsc.agiletechnologies.in \
  SPHINX_HOST=ownoutdoors.search.1 \
  SECRET_KEY_BASE=<your-secret> \
  always_use_ssl=true
```

Generate secrets locally:

```bash
bundle exec rails secret   # run twice for secret_key_base and app_encryption_key
```

---

## 6. Deploy the application

On your **workstation**:

```bash
git remote add dokku dokku@<SERVER_IP>:ownoutdoors
git push dokku <your-branch>:master
```

First deploy takes 10–20 minutes (Docker build + asset compilation).

Monitor build:

```bash
# on server
dokku logs ownoutdoors --tail
```

Confirm all three processes are running:

```bash
dokku ps:report ownoutdoors
# Expected: web=running, worker=running, search=running
```

---

## 7. Post-deploy setup (required)

Run on the **server** after the first successful deploy:

```bash
cd /opt/source/ror-ownoutdoorsc
sudo -E bash script/dokku/post-deploy.sh
sudo -E bash script/dokku/finish-setup.sh
```

Or manually:

### 7.1 Database

```bash
dokku run ownoutdoors bundle exec rails db:migrate
# First install only:
dokku run ownoutdoors bundle exec rails db:seed
```

### 7.2 Connect containers to shared network

After each deploy, ensure web and search are on the same network:

```bash
sudo docker network connect --alias ownoutdoors.search.1 ownoutdoors-internal ownoutdoors.search.1 2>/dev/null || true
sudo docker network connect --alias ownoutdoors.web.1 ownoutdoors-internal ownoutdoors.web.1 2>/dev/null || true
```

Verify connectivity from web container:

```bash
sudo docker exec ownoutdoors.web.1 nc -zv ownoutdoors.search.1 3564
# Expected: Connection succeeded
```

### 7.3 Landing page asset fix (.jpeg vs .jpg)

Category background images in `app/views/landing/index.haml` reference `.jpg` files but assets are stored as `.jpeg`. Either:

- Update the template to use `.jpeg` extensions, **or**
- Copy files inside the running web container after deploy:

```bash
sudo docker exec -u root ownoutdoors.web.1 bash -c '
cd /opt/app/app/assets/images
for f in ownOutDoors_category-Water-Sports_BG ownOutDoors_category-Boating_BG \
         ownOutDoors_category-Bicycles-Scooters-Motorcycles_BG ownOutDoors_category-fishing_BG \
         ownOutDoors_infoSectionBG; do
  cp "${f}.jpeg" "${f}.jpg" 2>/dev/null || true
done
chown -R app:app /opt/app/app/assets/images
'
sudo docker exec -u app ownoutdoors.web.1 bash -c \
  'cd /opt/app && RAILS_ENV=production bundle exec rake assets:precompile'
dokku ps:restart ownoutdoors web
```

---

## 8. HTTPS & domain (Let's Encrypt)

**DNS must point to this server first.**

```bash
dokku letsencrypt:set ownoutdoors email info@agileinfoways.com
dokku letsencrypt:enable ownoutdoors
```

Verify:

```bash
dokku certs:report ownoutdoors
curl -I https://ror-ownoutdoorsc.agiletechnologies.in/
curl -I https://ror-ownoutdoorsc.agiletechnologies.in/_health
```

If you get an HTTPS redirect loop, ensure:

```bash
dokku nginx:set ownoutdoors x-forwarded-proto-value '$scheme'
dokku proxy:build-config ownoutdoors
```

Auto-renewal is handled by the letsencrypt plugin (renews ~30 days before expiry).

---

## 9. Search (Sphinx) setup

### Architecture

| Container | Role |
|---|---|
| `search.1` | Runs `searchd` on port **3564** |
| `web.1` | Queries search via `SPHINX_HOST=ownoutdoors.search.1` |
| `worker.1` | Background jobs; also connects to search |

### Start / verify searchd

```bash
dokku logs ownoutdoors -p search -n 50
sudo docker exec ownoutdoors.search.1 ps aux | grep searchd
sudo docker exec ownoutdoors.search.1 mysql -h 127.0.0.1 -P 3564 -e "SHOW TABLES;"
```

### Populate search index

**Important:** Run reindex **inside the search container**, not via `dokku run` (ephemeral container cannot reach searchd):

```bash
sudo docker exec ownoutdoors.search.1 bash -c \
  'cd /opt/app && RAILS_ENV=production bundle exec rake ts:rebuild'
```

Check index count:

```bash
sudo docker exec ownoutdoors.search.1 mysql -h 127.0.0.1 -P 3564 \
  -e "SELECT COUNT(*) FROM listing_core;"
```

### Test category search pages

All should return **HTTP 200** (not "Search is currently unavailable"):

- `/s?category=water-sports`
- `/s?category=boating`
- `/s?category=motorcycles-scooters-bicycling`
- `/s?category=fishing`

---

## 10. Images & uploads

Listing photos, logos, and community images are stored under `/opt/app/public/system` (mounted at `/var/lib/dokku/data/storage/ownoutdoors/uploads`).

### If migrating from an existing production server

Copy uploads **before** going live:

```bash
# On OLD server:
tar czf /tmp/ownoutdoors-uploads.tar.gz -C /var/lib/dokku/data/storage/ownoutdoors uploads

# Copy to NEW server, then:
sudo tar xzf ownoutdoors-uploads.tar.gz -C /var/lib/dokku/data/storage/ownoutdoors/
sudo chown -R 32767:32767 /var/lib/dokku/data/storage/ownoutdoors/uploads
dokku ps:restart ownoutdoors web
```

Or with rsync:

```bash
rsync -avz --progress \
  old-server:/var/lib/dokku/data/storage/ownoutdoors/uploads/ \
  /var/lib/dokku/data/storage/ownoutdoors/uploads/
sudo chown -R 32767:32767 /var/lib/dokku/data/storage/ownoutdoors/uploads
```

### Temporary proxy (staging only)

If DB was copied but files were not, proxy `/system/` to production until uploads are synced:

```bash
sudo mkdir -p /home/dokku/ownoutdoors/nginx.conf.d
sudo tee /home/dokku/ownoutdoors/nginx.conf.d/01-proxy-system-images.conf > /dev/null << 'EOF'
location /system/ {
  proxy_pass https://ownoutdoors.com/system/;
  proxy_set_header Host ownoutdoors.com;
  proxy_ssl_server_name on;
}
EOF
sudo chown dokku:dokku /home/dokku/ownoutdoors/nginx.conf.d/01-proxy-system-images.conf
sudo dokku proxy:build-config ownoutdoors
```

Verify an image returns 200:

```bash
curl -I "https://ror-ownoutdoorsc.agiletechnologies.in/system/wide_logos/11722/header/Sharetribe_logo_v7.png"
```

---

## 11. Google Maps API

Maps fail with **"This page didn't load Google Maps correctly"** when the API key is not authorised for your domain.

### Google Cloud Console steps

1. Open [Google Cloud Console → Credentials](https://console.cloud.google.com/google/maps-apis/credentials)
2. Edit the **browser key** (used in `google_maps_key`)
3. Under **Application restrictions → HTTP referrers**, add:

   ```
   https://ror-ownoutdoorsc.agiletechnologies.in/*
   http://ror-ownoutdoorsc.agiletechnologies.in/*
   ```

4. Edit the **server key** (`google_maps_server_key`) — set **IP restrictions** to your server public IP
5. Enable these APIs on the project:
   - Maps JavaScript API
   - Places API
   - Geocoding API

6. Wait 2–5 minutes, then hard-refresh the browser

Keys are configured in `/var/lib/dokku/data/storage/ownoutdoors/config/config.yml` and/or `dokku config:set ownoutdoors google_maps_key=...`.

---

## 12. Verification checklist

Run after every fresh install or major deploy:

```bash
DOMAIN=ror-ownoutdoorsc.agiletechnologies.in

# Health & SSL
curl -sI "https://$DOMAIN/_health" | head -3          # expect 200
curl -sI "https://$DOMAIN/" | head -3                 # expect 200 or 301→200

# Category search (all must be 200, no "Search is currently unavailable")
for cat in water-sports boating motorcycles-scooters-bicycling fishing; do
  code=$(curl -sL -o /dev/null -w "%{http_code}" "https://$DOMAIN/s?category=$cat")
  echo "$cat: HTTP $code"
done

# Search connectivity
sudo docker exec ownoutdoors.web.1 nc -zv ownoutdoors.search.1 3564

# Sphinx index
sudo docker exec ownoutdoors.search.1 mysql -h 127.0.0.1 -P 3564 \
  -e "SELECT COUNT(*) FROM listing_core;"

# Process status
dokku ps:report ownoutdoors

# SSL cert
dokku certs:report ownoutdoors
```

### Expected final state

| Check | Expected |
|---|---|
| Homepage | Loads with category images |
| HTTPS | Valid Let's Encrypt certificate |
| Search categories | HTTP 200, listings visible |
| Listing images | HTTP 200 on `/system/images/...` |
| Google Maps | Map renders (after API key updated) |
| `/_health` | HTTP 200 |
| `web.1` | running |
| `search.1` | running, searchd on port 3564 |
| `worker.1` | running |

---

## 13. Day-to-day commands

```bash
# Logs
dokku logs ownoutdoors -t
dokku logs ownoutdoors -t -p search

# Deploy new code
git push dokku master

# Migrate after deploy
dokku run ownoutdoors bundle exec rails db:migrate

# Restart
dokku ps:restart ownoutdoors
dokku ps:restart ownoutdoors web

# Rails console
dokku enter ownoutdoors web
bundle exec rails c

# MySQL
dokku mysql:connect ownoutdoors-db

# Rebuild search index
sudo docker exec ownoutdoors.search.1 bash -c \
  'cd /opt/app && RAILS_ENV=production bundle exec rake ts:rebuild'
```

---

## 14. Troubleshooting

### "Marketplace temporarily unavailable" (500 on homepage)

**Cause:** Missing compiled assets (`.jpg` vs `.jpeg` mismatch on landing page).

**Fix:** See [§7.3 Landing page asset fix](#73-landing-page-asset-fix-jpeg-vs-jpg).

---

### "Search is currently unavailable"

**Cause:** Web container cannot reach Sphinx at `ownoutdoors.search.1:3564`.

**Fix:**

```bash
# 1. Ensure search container is running
dokku ps:report ownoutdoors

# 2. Connect to shared network
sudo docker network connect --alias ownoutdoors.search.1 ownoutdoors-internal ownoutdoors.search.1
sudo docker network connect --alias ownoutdoors.web.1 ownoutdoors-internal ownoutdoors.web.1

# 3. Test connectivity
sudo docker exec ownoutdoors.web.1 nc -zv ownoutdoors.search.1 3564

# 4. Reindex
sudo docker exec ownoutdoors.search.1 bash -c \
  'cd /opt/app && RAILS_ENV=production bundle exec rake ts:rebuild'
```

---

### Images return 404 (`/system/images/...`)

**Cause:** Uploads folder is empty (DB copied without files).

**Fix:** Sync uploads from production — see [§10 Images & uploads](#10-images--uploads).

---

### Google Maps error overlay

**Cause:** API key not authorised for your domain.

**Fix:** See [§11 Google Maps API](#11-google-maps-api).

---

### HTTPS redirect loop

**Cause:** Rails `always_use_ssl` + nginx not sending `X-Forwarded-Proto: https`.

**Fix:**

```bash
dokku nginx:set ownoutdoors x-forwarded-proto-value '$scheme'
dokku proxy:build-config ownoutdoors
```

---

### Let's Encrypt fails

**Cause:** DNS not pointing to this server yet.

**Fix:** Update A record, wait for propagation, then:

```bash
dokku letsencrypt:enable ownoutdoors
```

---

### Worker or search container won't start (port 3000 conflict)

**Cause:** `--publish 3000:3000` applied to all process types.

**Fix:**

```bash
dokku docker-options:remove ownoutdoors deploy "--publish 3000:3000"
dokku ps:restart ownoutdoors
```

Only nginx should bind ports 80/443; Passenger listens on 3000 **inside** the web container.

---

### `NO_VHOST=1` set accidentally

**Cause:** Disables Dokku nginx proxy entirely.

**Fix:**

```bash
dokku config:unset ownoutdoors NO_VHOST
dokku proxy:enable ownoutdoors
dokku proxy:build-config ownoutdoors
```

---

## Quick reference — install order

```text
 1. Ubuntu 22.04 server + open ports 80/443
 2. DNS A record → server IP
 3. Install Dokku + SSH key
 4. bash script/dokku/install-plugins.sh
 5. DOMAIN=... bash script/dokku/setup-app.sh
 6. Apply proxy/network fixes (section 3)
 7. Create config.yml + database.yml in storage (section 5)
 8. dokku config:set secrets (section 5.3)
 9. git push dokku master (section 6)
10. bash script/dokku/post-deploy.sh
11. bash script/dokku/finish-setup.sh
12. dokku letsencrypt:enable ownoutdoors (section 8)
13. Sync uploads from production (section 10)
14. Update Google Maps API key referrers (section 11)
15. Run verification checklist (section 12)
```

---

## Related files

| File | Purpose |
|---|---|
| `DOKKU-SETUP.md` | Original Dokku overview |
| `FRESH-SERVER-SETUP.md` | This guide (full fresh install) |
| `DEPLOY.md` | Git deploy workflow (push code to live) |
| `script/dokku/install-plugins.sh` | Install mysql, redis, memcached, letsencrypt |
| `script/dokku/setup-app.sh` | Create app, services, storage, nginx ports |
| `script/dokku/post-deploy.sh` | DB migrate/seed + initial Sphinx index |
| `script/dokku/finish-setup.sh` | Network, SSL proxy header, search reindex |
| `Procfile.production` | web, worker, search process definitions |
| `script/docker-entrypoint.sh` | Starts searchd in search.1 container |
| `config/thinking_sphinx.yml` | Sphinx port 3564, host config |
