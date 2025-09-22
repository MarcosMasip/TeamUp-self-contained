#!/usr/bin/env bash
set -euo pipefail

MODE="docker"
DC="docker compose"
if ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; then
  MODE="fallback"
else
  if ! docker compose version >/dev/null 2>&1; then
    if command -v docker-compose >/dev/null 2>&1; then
      DC="docker-compose"
    fi
  fi
fi

if [ ! -f .env ]; then
  cp .env.example .env
  echo "Created .env from template"
fi

echo "[prepare] Mode: $MODE"
if [ "$MODE" = "docker" ]; then
  echo "Building backend image..."
  docker build -t teamup-backend:local .
  echo "Building frontend image..."
  docker build -t teamup-frontend:local socialnetworkingapp-front
  echo "Pulling dependent images (postgres, mailpit)..."
  docker pull postgres:13.11-alpine || true
  docker pull axllent/mailpit:v1.18 || true
  echo "Running offline verification..."
  if ./scripts/offline-verify.sh; then
    echo "Offline verification passed."
  else
    echo "Offline verification failed. Investigate above references." >&2
    exit 1
  fi
  echo "Done. Run ./scripts/start.sh"
else
  echo "Fallback mode (no Docker). Ensuring Java & Node present."
  command -v java >/dev/null || { echo "Java not found"; exit 1; }
  command -v node >/dev/null || { echo "Node not found"; exit 1; }
  NODE_MAJOR=$(node -v | sed -E 's/v([0-9]+).*/\1/')
  if [ "$NODE_MAJOR" -ge 18 ]; then
    echo "[warn] Detected Node $NODE_MAJOR.x. This project targets Node 14 (see .nvmrc)."
    echo "[warn] You may see npm engine warnings. Using 'npm install' fallback if 'npm ci' fails."
  fi
  ./mvnw -q dependency:go-offline
  (
    cd socialnetworkingapp-front
    if ! npm ci; then
      echo "[info] npm ci failed (lock mismatch or engine). Regenerating lock with 'npm install'..."
      rm -f package-lock.json
      if ! npm install --legacy-peer-deps; then
        echo "[error] npm install failed even with --legacy-peer-deps. Please ensure Node 14.x or investigate peer conflicts." >&2
        exit 1
      fi
      echo "[info] New lock file generated using legacy peer deps. (Future runs will attempt npm ci first.)"
    fi
  )
  echo "Running offline verification (advisory)..."
  if ./scripts/offline-verify.sh; then
    echo "Offline verification passed."
  else
    echo "(Advisory) Offline verification reported potential external refs."
  fi
  echo "Fallback prepare complete. Run ./scripts/start.sh"
fi
