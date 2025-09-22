#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/util.sh"

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
  echo ".env missing. Run ./scripts/prepare.sh first."; exit 1;
fi
set -a; source .env; set +a

if [ "$MODE" = "docker" ]; then
  echo "Starting services ($DC)..."
  $DC up -d db mail
  echo "Waiting for database port..."
  retry_cmd 10 2 $DC exec -T db pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB" || echo "[warn] pg_isready did not fully succeed, continuing to backend start attempt"
  $DC up -d backend
  echo "Waiting for backend health..."
  for i in {1..30}; do
    if $DC ps | grep backend >/dev/null 2>&1 && curl -k -s https://localhost:${APP_BACKEND_PORT:-8443}/api/health | grep -q UP; then
      break
    fi
    sleep 2
  done
  $DC up -d frontend
  echo "Application started."
  echo "Frontend: http://localhost:${APP_FRONTEND_PORT:-4200}"
  echo "Backend API: https://localhost:${APP_BACKEND_PORT:-8443}/api" 
  echo "Mail UI: http://localhost:8025 (if using mail)"
  echo "Admin login: admin@admin.com / adminadmin"
else
  echo "Starting fallback local mode..."
  # Pre-flight port checks
  for p in "${APP_BACKEND_PORT:-8443}" "${APP_FRONTEND_PORT:-4200}"; do
    if ! check_port_free "$p"; then
      echo "Port $p already in use. Abort." >&2
      exit 1
    fi
  done
  ./mvnw spring-boot:run -Dspring-boot.run.profiles=local-h2 &
  BACK_PID=$!
  echo "Backend PID $BACK_PID"
  (
    cd socialnetworkingapp-front
    if command -v node >/dev/null 2>&1; then
      NODE_MAJ=$(node -v | sed -E 's/v([0-9]+).*/\1/')
      if [ "$NODE_MAJ" -ge 17 ]; then
        if [[ "${NODE_OPTIONS:-}" != *"--openssl-legacy-provider"* ]]; then
          export NODE_OPTIONS="${NODE_OPTIONS:-} --openssl-legacy-provider"
          echo "[info] Applied --openssl-legacy-provider for Webpack 4 compatibility (Node $NODE_MAJ)."
        fi
      fi
    fi
    npx ng serve
  ) &
  FRONT_PID=$!
  echo "Frontend PID $FRONT_PID"
  echo "Press Ctrl+C to stop."
  wait
fi
