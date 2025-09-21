#!/usr/bin/env bash
set -euo pipefail
BACKEND_PORT=${APP_BACKEND_PORT:-8443}
FRONTEND_PORT=${APP_FRONTEND_PORT:-4200}

echo "Checking backend..."
curl -k -s https://localhost:${BACKEND_PORT}/api/health | grep -q UP && echo "Backend OK" || { echo "Backend FAIL"; exit 1; }
echo "Checking frontend..."
curl -s http://localhost:${FRONTEND_PORT}/ | grep -qi '<app-root' && echo "Frontend OK" || { echo "Frontend FAIL"; exit 1; }
echo "All healthy."
