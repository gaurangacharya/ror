#!/bin/bash
# Deploy latest staging code on this server (docker-compose setup).
#
# Usage:
#   sudo bash deploy-staging.sh          # normal deploy (pull, migrate, restart)
#   sudo bash deploy-staging.sh --full   # also rebuild images + recompile assets
#
set -euo pipefail

APP_DIR="/opt/source/staging-ownoutdoorsc"
BRANCH="staging"
DOMAIN="jitsi.agiletechnologies.in"
FULL_DEPLOY=false

if [[ "${1:-}" == "--full" ]]; then
  FULL_DEPLOY=true
fi

cd "$APP_DIR"

echo "==> [1/6] Pulling latest code from origin/${BRANCH}..."
git pull origin "$BRANCH"

echo "==> [2/6] Fixing file ownership for container user (uid 1000)..."
chown -R 1000:1000 "$APP_DIR"

if $FULL_DEPLOY; then
  echo "==> [3/6] Rebuilding docker images (--full)..."
  docker compose up --build -d

  echo "==> [4/6] Installing gems..."
  docker compose run --rm web bundle install

  echo "==> [5/6] Precompiling assets..."
  docker compose exec web bash -c 'cd client && npm ci && cd .. && bundle exec rake assets:precompile'
else
  echo "==> [3/6] Skipping image rebuild (use --full if Gemfile/Dockerfile/package.json changed)"
  echo "==> [4/6] Skipping bundle install"
  echo "==> [5/6] Skipping asset precompile"
fi

echo "==> Running database migrations..."
docker compose run --rm web bundle exec rails db:migrate

echo "==> [6/6] Restarting web and worker..."
docker compose restart web worker

echo "==> Waiting for app to boot..."
sleep 12

echo ""
echo "==> Container status:"
docker compose ps

echo ""
echo "==> Health check (https://${DOMAIN}/_health):"
curl -sI "https://${DOMAIN}/_health" | head -5 || true

echo ""
echo "Deploy complete."
