#!/usr/bin/env bash
set -euo pipefail

MODE="docker"
if ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; then
  MODE="fallback"
fi

if [ ! -f .env ]; then
  echo ".env missing. Run ./scripts/prepare.sh first."; exit 1;
fi
set -a; source .env; set +a

if [ "$MODE" = "docker" ]; then
  echo "Starting services (docker compose)..."
  docker compose up -d db mail
  echo "Waiting for database..."
  sleep 10
  docker compose up -d backend
  echo "Waiting for backend health..."
  for i in {1..30}; do
    if docker compose ps | grep backend >/dev/null 2>&1 && curl -k -s https://localhost:${APP_BACKEND_PORT:-8443}/api/health | grep -q UP; then
      break
    fi
    sleep 2
  done
  docker compose up -d frontend
  echo "Application started."
  echo "Frontend: http://localhost:${APP_FRONTEND_PORT:-4200}"
  echo "Backend API: https://localhost:${APP_BACKEND_PORT:-8443}/api" 
  echo "Mail UI: http://localhost:8025 (if using mail)"
  echo "Admin login: admin@admin.com / adminadmin"
else
  echo "Starting fallback local mode..."
  ./mvnw spring-boot:run -Dspring-boot.run.profiles=local-h2 &
  BACK_PID=$!
  echo "Backend PID $BACK_PID"
  (cd socialnetworkingapp-front && npx ng serve) &
  FRONT_PID=$!
  echo "Frontend PID $FRONT_PID"
  echo "Press Ctrl+C to stop."
  wait
fi
