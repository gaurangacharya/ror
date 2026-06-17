#!/bin/bash
set -euo pipefail

if ! command -v dokku >/dev/null 2>&1; then
  echo "ERROR: dokku is not installed. Run this on your Dokku droplet after deploying the app."
  exit 1
fi

APP_NAME="${APP_NAME:-ownoutdoors}"

echo "Running first-time database setup for '${APP_NAME}'..."
dokku run "$APP_NAME" bundle exec rails db:create db:migrate db:seed

echo "Populating Sphinx search index..."
dokku run "$APP_NAME" bundle exec rake ts:index || \
  dokku run "$APP_NAME" bundle exec rake ts:rebuild

echo "Post-deploy setup complete."
