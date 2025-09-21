#!/usr/bin/env bash
set -euo pipefail
echo "Starting dev mode (db + mail in docker, local backend/frontend)..."
docker compose up -d db mail
./mvnw spring-boot:run -Dspring-boot.run.profiles=mock,local-h2 &
BACK_PID=$!
(cd socialnetworkingapp-front && npx ng serve --proxy-config proxy.conf.json) &
FRONT_PID=$!
trap 'echo Stopping...; kill $BACK_PID $FRONT_PID 2>/dev/null || true; docker compose down' INT TERM
wait
