#!/bin/bash
set -euo pipefail

if ! command -v dokku >/dev/null 2>&1; then
  echo "ERROR: dokku is not installed. Run this on your Dokku droplet after installing Dokku."
  exit 1
fi

APP_NAME="${APP_NAME:-staging-ownoutdoorsc}"
DOMAIN="${DOMAIN:-jitsi.agiletechnologies.in}"
SPHINX_HOST="${SPHINX_HOST:-${APP_NAME}.search.1}"

if ! dokku apps:exists "$APP_NAME" 2>/dev/null; then
  dokku apps:create "$APP_NAME"
fi

echo "Provisioning MySQL..."
if ! dokku mysql:exists "${APP_NAME}-db" 2>/dev/null; then
  dokku mysql:create "${APP_NAME}-db" \
    --image mysql \
    --image-version 5.7.37 \
    --custom-env "MYSQL_CHARSET=utf8mb4,MYSQL_COLLATION=utf8mb4_unicode_ci"
fi
dokku mysql:link "${APP_NAME}-db" "$APP_NAME" || true

echo "Provisioning Redis..."
if ! dokku redis:exists "${APP_NAME}-redis" 2>/dev/null; then
  dokku redis:create "${APP_NAME}-redis" \
    --image redis \
    --image-version 6.0.16-alpine
fi
dokku redis:link "${APP_NAME}-redis" "$APP_NAME" || true

echo "Provisioning Memcached..."
if ! dokku memcached:exists "${APP_NAME}-memcached" 2>/dev/null; then
  dokku memcached:create "${APP_NAME}-memcached"
fi
dokku memcached:link "${APP_NAME}-memcached" "$APP_NAME" || true

echo "Configuring persistent storage..."
sudo mkdir -p \
  "/var/lib/dokku/data/storage/${APP_NAME}/sphinx" \
  "/var/lib/dokku/data/storage/${APP_NAME}/uploads" \
  "/var/lib/dokku/data/storage/${APP_NAME}/assets"
sudo chown -R 32767:32767 "/var/lib/dokku/data/storage/${APP_NAME}"

dokku storage:mount "$APP_NAME" \
  "/var/lib/dokku/data/storage/${APP_NAME}/sphinx:/opt/app/sphinx" || true
dokku storage:mount "$APP_NAME" \
  "/var/lib/dokku/data/storage/${APP_NAME}/uploads:/opt/app/public/system" || true
dokku storage:mount "$APP_NAME" \
  "/var/lib/dokku/data/storage/${APP_NAME}/assets:/opt/app/public/assets" || true

echo "Configuring Dockerfile builder..."
dokku builder:set "$APP_NAME" selected dockerfile
dokku builder-dockerfile:set "$APP_NAME" dockerfile-path Dockerfile
dokku ps:set "$APP_NAME" procfile-path Procfile.production

echo "Configuring Nginx proxy..."
dokku ports:set "$APP_NAME" http:80:3000 https:443:3000
dokku nginx:set "$APP_NAME" proxy-read-timeout 120s
dokku nginx:set "$APP_NAME" proxy-connect-timeout 120s

if [ -n "$DOMAIN" ]; then
  dokku domains:add "$APP_NAME" "$DOMAIN" || true
fi

echo "Setting core environment variables..."
dokku config:set --no-restart "$APP_NAME" \
  RAILS_ENV=production \
  NODE_ENV=production \
  RACK_ENV=production \
  RAILS_SERVE_STATIC_FILES=true \
  RAILS_LOG_TO_STDOUT=true \
  PASSENGER_MIN_INSTANCES=1 \
  PASSENGER_MAX_POOL_SIZE=3 \
  DOMAIN="$DOMAIN" \
  SPHINX_HOST="$SPHINX_HOST"

echo "Scaling process formation..."
dokku ps:scale "$APP_NAME" web=1 worker=1 search=1

echo "App '${APP_NAME}' configured."
echo "Next steps:"
echo "  1. Set secrets: dokku config:set ${APP_NAME} SECRET_KEY_BASE=... SMTP_*=... AWS_*=..."
echo "  2. Deploy from workstation: git push dokku master"
echo "  3. First-time setup: script/dokku/post-deploy.sh"
