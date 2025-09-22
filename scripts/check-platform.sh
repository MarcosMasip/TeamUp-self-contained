#!/usr/bin/env bash
set -euo pipefail
print_ver() { echo -n "$1: "; if command -v "$2" >/dev/null 2>&1; then $2 $3 || true; else echo 'NOT FOUND'; fi }
print_ver "Java" "java" "-version"
print_ver "Node" "node" "-v"
print_ver "NPM" "npm" "-v"
print_ver "Docker" "docker" "--version"
if command -v docker >/dev/null 2>&1; then
  if docker compose version >/dev/null 2>&1; then echo "Docker Compose: plugin available"; elif command -v docker-compose >/dev/null 2>&1; then echo "Docker Compose: legacy binary available"; else echo "Docker Compose: NOT FOUND"; fi
fi
