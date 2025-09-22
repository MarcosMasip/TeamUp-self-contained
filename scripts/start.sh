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
      echo "Port $p already in use." >&2
      # Show process holding the port (macOS/Linux)
      if command -v lsof >/dev/null 2>&1; then
        echo "Process using port $p:" >&2
        lsof -iTCP:"$p" -sTCP:LISTEN -n -P || true
        # If this is the backend port and looks like a prior Java/Spring instance, offer auto-kill
        if [ "$p" = "${APP_BACKEND_PORT:-8443}" ]; then
          STALE_PID=$(lsof -t -iTCP:"$p" -sTCP:LISTEN | head -1 || true)
          if [ -n "${STALE_PID}" ]; then
            CMD_LINE=$(ps -p "$STALE_PID" -o command= || echo "")
            if echo "$CMD_LINE" | grep -qi "spring" || echo "$CMD_LINE" | grep -qi "SocialNetworkingApp"; then
              echo "Attempting to terminate stale backend process PID $STALE_PID..." >&2
              kill "$STALE_PID" 2>/dev/null || true
              sleep 1
              if check_port_free "$p"; then
                echo "Stale process removed; continuing startup." >&2
                continue
              else
                echo "Auto-termination failed; port still busy." >&2
              fi
            fi
          fi
        fi
      fi
      echo "Resolve by: (a) stopping the process above, or (b) editing .env to change APP_BACKEND_PORT / APP_FRONTEND_PORT and re-run prepare/start." >&2
      echo "Abort." >&2
      exit 1
    fi
  done
  ./mvnw spring-boot:run -Dspring-boot.run.profiles=local-h2 &
  BACK_PID=$!
  echo "Backend PID $BACK_PID"
  # Wait for backend health (simple loop up to 30s)
  for i in {1..30}; do
    if curl -s -o /dev/null -w '%{http_code}' http://localhost:${APP_BACKEND_PORT:-8443}/api/health | grep -q 200; then
      echo "[info] Backend health endpoint is UP."; break; fi
    sleep 1
    if [ $i -eq 30 ]; then echo "[warn] Backend health not confirmed yet; continuing anyway."; fi
  done
  FRONTEND_SSL_ENABLED=${FRONTEND_SSL:-1}
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
    if [ "$FRONTEND_SSL_ENABLED" = "0" ]; then
      echo "[info] Starting Angular dev server without SSL (FRONTEND_SSL=0)."
      npx ng serve --ssl false
    else
      npx ng serve
    fi
  ) &
  FRONT_PID=$!
  echo "Frontend PID $FRONT_PID"
  echo "--------------------------------------------------"
  if [ "$FRONTEND_SSL_ENABLED" = "0" ]; then
    echo "Open Frontend:  http://localhost:${APP_FRONTEND_PORT:-4200}"
  else
    echo "Open Frontend:  https://localhost:${APP_FRONTEND_PORT:-4200}"
  fi
  echo "Backend API:    https://localhost:${APP_BACKEND_PORT:-8443}/api" 
  echo "Health Check:   https://localhost:${APP_BACKEND_PORT:-8443}/api/health"
  if [ "$FRONTEND_SSL_ENABLED" = "1" ]; then
    echo "Note: Browser will warn about self-signed certificate. You can proceed (Advanced > Continue) or restart with FRONTEND_SSL=0 ./scripts/start.sh for HTTP."
  fi
  echo "Mail (Docker only): http://localhost:8025"
  echo "Admin login:    admin@admin.com / adminadmin"
  echo "Press Ctrl+C to stop (both processes)."
  wait
fi
