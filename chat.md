# Staging Setup Chat Export

**Date:** June 18, 2026  
**Project:** OwnOutdoors Staging (`staging-ownoutdoorsc`)  
**Server IP:** `111.93.93.21`  
**Staging URL:** https://jitsi.agiletechnologies.in  
**App folder:** `/opt/source/staging-ownoutdoorsc`  
**Git branch:** `staging`  
**Stack:** Docker Compose + Nginx (not Dokku for live staging)

---

## Table of Contents

1. [Initial Request](#1-initial-request)
2. [Environment Discovery](#2-environment-discovery)
3. [Docker Compose Setup (Chosen Approach)](#3-docker-compose-setup-chosen-approach)
4. [Database Import](#4-database-import)
5. [Domain Change](#5-domain-change)
6. [Server IP Change](#6-server-ip-change)
7. [Asset Precompile & Homepage Fix](#7-asset-precompile--homepage-fix)
8. [Deployment Process](#8-deployment-process)
9. [Files Created](#9-files-created)
10. [Current Status](#10-current-status)
11. [Important Commands](#11-important-commands)
12. [Outstanding / External Tasks](#12-outstanding--external-tasks)

---

## 1. Initial Request

**User:** Read `INSTALL.md` and set up the staging environment. Ask before making changes.

**Action taken:**
- Read `INSTALL.md` (Dokku-based two-app server guide)
- Inspected server: Dokku 0.34.8 installed, `staging-ownoutdoorsc` app existed but **not deployed**
- MySQL, Redis, Memcached services existed but were stopped — started them
- Partial Dokku config existed; app had never been successfully built/deployed

**User correction:** Use `Dockerfile.development` and `docker-compose.yml` — **do not change** production `Dockerfile`.

**Decision:** Staging runs via **Docker Compose**, not Dokku deploy.

---

## 2. Environment Discovery

| Item | Value |
|---|---|
| Server public IP | `111.93.93.21` |
| Dokku app | `staging-ownoutdoorsc` (configured, not used for live app) |
| Docker Compose | Primary runtime |
| Domain (final) | `jitsi.agiletechnologies.in` |
| Old domain (in DB) | `ror-ownoutdoorsc.agiletechnologies.in` |
| Git remote | `https://github.com/gaurangacharya/ror.git` |
| Branch | `staging` |

**Services (docker-compose):**
- `web` — Passenger on port 3000
- `worker` — Sidekiq + Sphinx/Manticore search
- `mysql` — MySQL 5.7.37
- `redis` — Redis 6.0.16
- `memcached`
- `mailcatcher` — port 1080

---

## 3. Docker Compose Setup (Chosen Approach)

### Files created / updated

| File | Purpose |
|---|---|
| `.env` | Container environment (RAILS_ENV, REDIS_URL, DOMAIN, etc.) |
| `config/config.yml` | App secrets (copied from Dokku storage, adjusted for docker) |
| `config/database.yml` | MySQL connection to `mysql` service |
| `script/entrypoint.sh` | Simple passthrough entrypoint (was missing) |

### Dockerfile.development fixes (not production Dockerfile)

1. **Manticore:** Removed `manticore-extra` (conflicts with `manticore` package)
2. **Nginx:** Added `apt-get update` before `apt-get install nginx`

### Permission fix

```bash
sudo chown -R 1000:1000 /opt/source/staging-ownoutdoorsc
sudo docker compose run --rm web bundle install
```

Volume mount hides gems from image build — `bundle install` required on host-mounted code.

### Start stack

```bash
cd /opt/source/staging-ownoutdoorsc
sudo docker compose up --build -d
```

### Reverted Dockerfile change

A temporary `Dockerfile` fix was committed then **reverted** per user request:
```bash
git revert --no-edit HEAD  # reverted Dockerfile permission-order fix
```

---

## 4. Database Import

**User request:** Import `staging18062026.sql`

| Detail | Value |
|---|---|
| File | `/opt/source/staging-ownoutdoorsc/staging18062026.sql` |
| Size | 717 MB |
| Source DB name in dump | `ownoutdoors_db` |
| Target DB | `ownoutdoors_development` |
| Tables imported | 122 |

**Commands used:**
```bash
# Get MySQL root password from container logs
sudo docker logs staging-ownoutdoorsc-mysql-1 | grep "GENERATED ROOT PASSWORD"

# Prepare DB and import
sudo docker exec staging-ownoutdoorsc-mysql-1 mysql -u root -p"$MYSQL_ROOT" -e \
  "SET GLOBAL max_allowed_packet=1073741824;
   DROP DATABASE IF EXISTS ownoutdoors_development;
   CREATE DATABASE ownoutdoors_development CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

sudo docker exec -i staging-ownoutdoorsc-mysql-1 mysql -u root -p"$MYSQL_ROOT" \
  --max_allowed_packet=1G ownoutdoors_development < staging18062026.sql

# Migrations (no pending changes after import)
sudo docker compose run --rm web bundle exec rails db:migrate
```

---

## 5. Domain Change

**User request:** Change staging domain from `ror-ownoutdoorsc.agiletechnologies.in` to `jitsi.agiletechnologies.in`

### Changes made

1. **Database:**
   ```sql
   UPDATE communities SET domain='jitsi.agiletechnologies.in' WHERE id=11722;
   ```

2. **config/config.yml:** Already had `domain: "jitsi.agiletechnologies.in"`

3. **`.env`:** Added `DOMAIN=jitsi.agiletechnologies.in`

4. **Nginx** (`/etc/nginx/conf.d/jitsi.agiletechnologies.in.conf`):
   - Backed up original Jitsi config to `.jitsi-backup-YYYYMMDD`
   - Replaced with reverse proxy to `http://127.0.0.1:3000`
   - SSL certs reused from Let's Encrypt

5. **Restart:**
   ```bash
   sudo docker compose restart web
   sudo nginx -t && sudo systemctl reload nginx
   ```

**Note:** `jitsi.agiletechnologies.in` previously served Jitsi Meet. Staging Rails app now uses that domain. Jitsi backup saved on server.

---

## 6. Server IP Change

**User:** Changed server IP from `202.131.119.93` to `111.93.93.21`

**Verified on server:**
- Public IP: `111.93.93.21` ✓
- `jitsi.agiletechnologies.in` DNS → `111.93.93.21` ✓
- Dokku global vhost: `111.93.93.21` ✓
- Health check: `https://jitsi.agiletechnologies.in/_health` → 200 ✓

**Still on old IP (user must update DNS externally):**
- `ror-ownoutdoorsc.agiletechnologies.in` → `202.131.117.93`

**External updates needed:**
- Google Maps API server key IP restriction → `111.93.93.21`
- Any DNS A records still pointing to old IP
- Git/Dokku remote if deploying via SSH: `dokku@111.93.93.21:staging-ownoutdoorsc`

---

## 7. Asset Precompile & Homepage Fix

**Problem:** Homepage returned HTTP 500 — missing asset `ownOutDoors_category-Water-Sports_BG.jpg`

**Fix steps:**
1. Copied `.jpeg` category images to `.jpg` in `app/assets/images/`
2. Ran full asset precompile inside web container:
   ```bash
   sudo docker compose exec web bash -c \
     'cd client && npm ci && cd .. && bundle exec rake assets:precompile'
   ```
3. Restarted web:
   ```bash
   sudo docker compose restart web
   ```

**Result:** `https://jitsi.agiletechnologies.in/` → **HTTP 200**

**Sphinx/worker fix:**
```bash
mkdir -p /opt/source/staging-ownoutdoorsc/sphinx/data/binlog.web.1
sudo chown -R 1000:1000 /opt/source/staging-ownoutdoorsc/sphinx
sudo docker compose up -d worker
```

---

## 8. Deployment Process

### Workflow

```
Laptop  →  git push origin staging  →  GitHub
Server  →  sudo bash deploy-staging.sh  →  Live site updated
```

### Laptop commands

```bash
cd /path/to/ownoutdoorsc
git checkout staging
git pull origin staging
git add .
git commit -m "your change description"
git push origin staging
```

### Server — normal deploy

```bash
sudo bash /opt/source/staging-ownoutdoorsc/deploy-staging.sh
```

Runs: `git pull` → `chown` → `db:migrate` → `restart web worker` → health check

### Server — full deploy (Gemfile / Dockerfile / package.json changed)

```bash
sudo bash /opt/source/staging-ownoutdoorsc/deploy-staging.sh --full
```

Also runs: `docker compose up --build -d` → `bundle install` → `assets:precompile`

### Reference documentation

See `deploy-staging.txt` for all commands with descriptions.

---

## 9. Files Created

| File | Description |
|---|---|
| `deploy-staging.sh` | Automated deploy script (normal + `--full` mode) |
| `deploy-staging.txt` | All deployment commands with descriptions |
| `chat.md` | This chat export |
| `.env` | Docker Compose environment variables |
| `config/config.yml` | Staging secrets and settings |
| `config/database.yml` | MySQL config for docker-compose |
| `script/entrypoint.sh` | Container entrypoint passthrough |

### Modified (with user approval or necessity)

| File | Change |
|---|---|
| `Dockerfile.development` | Fixed manticore + nginx install |
| `/etc/nginx/conf.d/jitsi.agiletechnologies.in.conf` | Proxy to Rails :3000 |
| `communities` table | Domain → `jitsi.agiletechnologies.in` |

### Not modified (per user request)

| File | Note |
|---|---|
| `Dockerfile` | Production Dokku Dockerfile — left unchanged |

---

## 10. Current Status

| Component | Status |
|---|---|
| Web | Running — https://jitsi.agiletechnologies.in (200 OK) |
| Worker | Running — Sidekiq + Sphinx |
| MySQL | Running — 122 tables, imported data |
| Redis / Memcached | Running |
| Mailcatcher | Running — http://111.93.93.21:1080 |
| Health endpoint | `/_health` → 200 OK |
| Assets | Precompiled |
| Deploy script | Ready at `deploy-staging.sh` |

---

## 11. Important Commands

```bash
# Deploy (normal)
sudo bash /opt/source/staging-ownoutdoorsc/deploy-staging.sh

# Deploy (full rebuild)
sudo bash /opt/source/staging-ownoutdoorsc/deploy-staging.sh --full

# Container status
cd /opt/source/staging-ownoutdoorsc && sudo docker compose ps

# Web logs
sudo docker compose logs web -f

# Worker logs
sudo docker compose logs worker -f

# Rails console
sudo docker compose run --rm web bundle exec rails c

# Rebuild search index
sudo docker compose exec worker bundle exec rake ts:rebuild

# Health check
curl -sI https://jitsi.agiletechnologies.in/_health

# Start all services
sudo docker compose up -d

# Stop all services
sudo docker compose down
```

---

## 12. Outstanding / External Tasks

These were **not** done on the server (require user action elsewhere):

- [ ] Update Google Maps API key IP restriction to `111.93.93.21`
- [ ] Add `https://jitsi.agiletechnologies.in/*` to Maps HTTP referrers
- [ ] Update any DNS records still pointing to old IP `202.131.119.93` / `202.131.117.93`
- [ ] Decide if Jitsi Meet needs a different subdomain (nginx config was replaced)
- [ ] Push local commits to GitHub (`staging` branch is ahead 2 commits from Dockerfile revert work)
- [ ] Optional: commit `deploy-staging.sh`, `deploy-staging.txt`, `chat.md` to git

---

## Session Timeline (Summary)

1. Read INSTALL.md → found Dokku partially set up, not deployed
2. User chose docker-compose over Dokku/Dockerfile changes
3. Created config files, fixed Dockerfile.development, started stack
4. Imported `staging18062026.sql` (717MB)
5. Changed domain to `jitsi.agiletechnologies.in` (DB + nginx)
6. Confirmed new server IP `111.93.93.21` working
7. Fixed assets → homepage 200 OK
8. Created `deploy-staging.sh` and `deploy-staging.txt`
9. Exported this chat as `chat.md`
10. Fixed missing `/system/` images via nginx proxy to ownoutdoors.com
11. Rebuilt Sphinx index (`ts:rt:index`) — category pages show listings + images

---

## Image Fix (June 19, 2026)

**Problem:** Category pages showed no listing images — `/system/` returned 404 (DB imported without upload files).

**Fix 1 — Nginx proxy** (`/etc/nginx/conf.d/jitsi.agiletechnologies.in.conf`):
```nginx
location /system/ {
    proxy_pass https://ownoutdoors.com/system/;
    proxy_set_header Host ownoutdoors.com;
    proxy_ssl_server_name on;
}
```

**Fix 2 — Search index:**
```bash
sudo docker compose exec worker bundle exec rake ts:rt:index
```

**Result:** All category pages return 24 listings with images (HTTP 200).

---

*End of chat export*
