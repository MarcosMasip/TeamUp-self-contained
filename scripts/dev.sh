#!/usr/bin/env bash
set -euo pipefail
echo "Starting dev mode (db + mail in docker, local backend/frontend)..."
DC="docker compose"
if ! docker compose version >/dev/null 2>&1; then
	if command -v docker-compose >/dev/null 2>&1; then
		DC="docker-compose"
	fi
fi
$DC up -d db mail
./mvnw spring-boot:run -Dspring-boot.run.profiles=mock,local-h2 &
BACK_PID=$!
(cd socialnetworkingapp-front && npx ng serve --proxy-config proxy.conf.json) &
FRONT_PID=$!
trap 'echo Stopping...; kill $BACK_PID $FRONT_PID 2>/dev/null || true; $DC down' INT TERM
wait
