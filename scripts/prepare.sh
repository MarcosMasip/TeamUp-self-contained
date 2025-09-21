#!/usr/bin/env bash
set -euo pipefail

MODE="docker"
if ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; then
  MODE="fallback"
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
  echo "Done. Run ./scripts/start.sh"
else
  echo "Fallback mode (no Docker). Ensuring Java & Node present."
  command -v java >/dev/null || { echo "Java not found"; exit 1; }
  command -v node >/dev/null || { echo "Node not found"; exit 1; }
  ./mvnw -q dependency:go-offline
  (cd socialnetworkingapp-front && npm ci)
  echo "Fallback prepare complete. Run ./scripts/start.sh"
fi
