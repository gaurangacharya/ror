#!/bin/bash
set -euo pipefail

# Post-deploy finishing steps for a fresh Dokku install.
# Run on the Dokku server AFTER the first git push deploy succeeds.
#
# Usage:
#   sudo -E bash script/dokku/finish-setup.sh
#
# Environment overrides: APP_NAME, DOMAIN, NETWORK_NAME

if ! command -v dokku >/dev/null 2>&1; then
  echo "ERROR: dokku is not installed."
  exit 1
fi

APP_NAME="${APP_NAME:-ownoutdoors}"
NETWORK_NAME="${NETWORK_NAME:-ownoutdoors-internal}"
DOMAIN="${DOMAIN:-}"

echo "==> Finishing setup for '${APP_NAME}'..."

echo "==> Enabling nginx proxy..."
dokku proxy:enable "$APP_NAME" 2>/dev/null || true
dokku config:unset "$APP_NAME" NO_VHOST 2>/dev/null || true

echo "==> Configuring nginx SSL proxy headers..."
dokku nginx:set "$APP_NAME" x-forwarded-proto-value '$scheme'
dokku nginx:set "$APP_NAME" proxy-read-timeout 120s
dokku nginx:set "$APP_NAME" proxy-connect-timeout 120s

echo "==> Removing host port 3000 publish from deploy (nginx handles 80/443)..."
dokku docker-options:remove "$APP_NAME" deploy "--publish 3000:3000" 2>/dev/null || true

if [ -n "$DOMAIN" ]; then
  echo "==> Setting domain to ${DOMAIN}..."
  dokku domains:set "$APP_NAME" "$DOMAIN" 2>/dev/null || true
fi

echo "==> Creating shared Docker network '${NETWORK_NAME}'..."
docker network create "$NETWORK_NAME" 2>/dev/null || true
dokku network:set "$APP_NAME" initial-network "$NETWORK_NAME" 2>/dev/null || true

connect_container() {
  local container="$1"
  local alias="$2"
  if docker ps --format '{{.Names}}' | grep -qx "$container"; then
    docker network connect --alias "$alias" "$NETWORK_NAME" "$container" 2>/dev/null || true
    echo "    Connected ${container} -> ${NETWORK_NAME} (alias: ${alias})"
  else
    echo "    Skipped ${container} (not running)"
  fi
}

echo "==> Connecting app containers to shared network..."
connect_container "${APP_NAME}.web.1" "${APP_NAME}.web.1"
connect_container "${APP_NAME}.search.1" "${APP_NAME}.search.1"
connect_container "${APP_NAME}.worker.1" "${APP_NAME}.worker.1"

WEB_CID=$(docker ps --filter "name=${APP_NAME}.web.1" --format '{{.ID}}' | head -1)
if [ -n "$WEB_CID" ]; then
  echo "==> Testing web -> search connectivity..."
  if docker exec "$WEB_CID" nc -zv "${APP_NAME}.search.1" 3564 2>/dev/null; then
    echo "    OK: web can reach search on port 3564"
  else
    echo "    WARNING: web cannot reach ${APP_NAME}.search.1:3564"
    echo "    Try: dokku ps:restart ${APP_NAME} search"
  fi
fi

SEARCH_CID=$(docker ps --filter "name=${APP_NAME}.search.1" --format '{{.ID}}' | head -1)
if [ -n "$SEARCH_CID" ]; then
  echo "==> Populating Sphinx search index (inside search container)..."
  docker exec "$SEARCH_CID" bash -c \
    'cd /opt/app && RAILS_ENV=production bundle exec rake ts:rebuild' 2>&1 | tail -5 || \
    echo "    WARNING: ts:rebuild failed — check: dokku logs ${APP_NAME} -p search"
fi

echo "==> Rebuilding nginx config..."
dokku proxy:build-config "$APP_NAME"

echo ""
echo "Finish setup complete for '${APP_NAME}'."
echo ""
echo "Next steps:"
echo "  1. Enable SSL (after DNS points here):"
echo "       dokku letsencrypt:set ${APP_NAME} email you@example.com"
echo "       dokku letsencrypt:enable ${APP_NAME}"
echo "  2. Sync uploads from production (see FRESH-SERVER-SETUP.md section 10)"
echo "  3. Add domain to Google Maps API key referrers (see FRESH-SERVER-SETUP.md section 11)"
echo "  4. Run verification checklist in FRESH-SERVER-SETUP.md section 12"
