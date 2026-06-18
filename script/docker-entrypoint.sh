#!/bin/bash
set -e

# DYNO env var is provided by Dokku (e.g., web.1, worker.1)
if [ -z "${DYNO}" ]; then
  CONTAINER_ID=$(hostname | cut -c1-8)
  export DYNO="run.${CONTAINER_ID}.$$"
  echo "DYNO not set, using generated value: ${DYNO}"
fi

# Only search.1 runs searchd with exclusive access to index files
# Other containers connect to search.1's searchd via MySQL protocol (port 3564)
if [[ "${DYNO}" == "search.1" ]]; then
  echo "This container (${DYNO}) will run searchd and serve all containers via network..."

  # Cleanup old binlog directories and PID files from terminated containers (older than 1 day)
  find /opt/app/sphinx/data/binlog.run.* -maxdepth 0 -type d -mtime +1 -exec rm -rf {} \; 2>/dev/null || true
  find /opt/app/sphinx -maxdepth 1 -name "searchd.run.*.pid" -mtime +1 -delete 2>/dev/null || true
  find /opt/app/sphinx/data -maxdepth 1 -name "production.run.*.sphinx.conf" -mtime +1 -delete 2>/dev/null || true

  # Create binlog directory for search.1
  mkdir -p "/opt/app/sphinx/data/binlog.${DYNO}"

  # Remove all lock files including binlog locks from previous container (60s grace period overlap)
  echo "Removing stale lock files..."
  find /opt/app/sphinx -name '*.lock' -delete 2>/dev/null || true
  pkill -f searchd 2>/dev/null || true
  sleep 1

  # Remove old pids and conf files if they exist
  rm -f "/opt/app/sphinx/searchd.${DYNO}.pid" 2>/dev/null
  rm -f "/opt/app/sphinx/data/production.${DYNO}.sphinx.conf" 2>/dev/null

  # Generate Thinking Sphinx configuration
  echo "Generating Thinking Sphinx configuration..."
  if bundle exec rake ts:configure; then
    echo "Thinking Sphinx configuration generated successfully"
  else
    echo "WARNING: Thinking Sphinx configuration failed - continuing so the app can boot."
  fi

  # Start Sphinx with existing persisted index data from the shared volume.
  # RT indexes persist on disk and are updated in real-time by Rails model callbacks,
  # so a full reindex is only needed when the index is empty (first deploy or corruption).
  # Using ts:start (not ts:rebuild) preserves existing data — no empty search window.
  echo "Starting Sphinx daemon..."
  if bundle exec rake ts:start; then
    echo "Sphinx daemon started with existing index data"
  else
    echo "ts:start failed, falling back to full rebuild..."
    bundle exec rake ts:rebuild || echo "WARNING: Sphinx rebuild failed"
  fi

  sleep 2

  # Check if RT index has data — only reindex if empty (first deploy or after corruption)
  COUNT=$(mysql -h 127.0.0.1 -P 3564 -N -e "SELECT COUNT(*) FROM listing_core;" 2>/dev/null | tr -d '[:space:]')
  if [ -n "$COUNT" ] && [ "$COUNT" -gt 0 ] 2>/dev/null; then
    echo "RT index already has $COUNT listings, skipping reindex"
  else
    echo "RT index is empty, populating from MySQL..."
    bundle exec rake ts:rt:index || echo "WARNING: RT index population failed"
  fi

  # Keep the search container running
  echo "Search container is ready. Keeping container alive..."
  tail -f /dev/null
else
  if [ -n "${SPHINX_HOST:-}" ]; then
    SEARCH_HOST="${SPHINX_HOST}"
  elif [ -n "${DOKKU_APP_NAME:-}" ]; then
    SEARCH_HOST="${DOKKU_APP_NAME}.search.1"
  else
    SEARCH_HOST="ownoutdoors-staging.search.local"
  fi
  SEARCH_PORT="3564"

  echo "Container ${DYNO} will connect to searchd on ${SEARCH_HOST}:3564 (not starting local searchd)"
  echo "RT index updates (via model callbacks) will be sent to search.1 via SphinxQL"

  # Wait for search container to be ready
  echo "Waiting for search container to be ready..."

  # Wait up to 60 seconds for search container to accept connections
  for i in {1..60}; do
    if nc -z "$SEARCH_HOST" "$SEARCH_PORT" 2>/dev/null; then
      echo "Search container is ready! Proceeding with startup..."
      break
    fi
    if [ $i -eq 60 ]; then
      echo "WARNING: Search container not ready after 60 seconds - proceeding anyway"
    else
      echo "Waiting for search container... (attempt $i/60)"
      sleep 1
    fi
  done
fi

exec "$@"
