#!/usr/bin/env bash
# Shared utility functions for scripts.
set -euo pipefail

check_port_free() {
  local port="$1"
  if lsof -iTCP:"$port" -sTCP:LISTEN -Pn >/dev/null 2>&1; then
    return 1
  fi
  return 0
}

wait_for_port() {
  local host="$1"; shift
  local port="$1"; shift
  local attempts=${1:-30}
  local sleep_s=${2:-1}
  for ((i=1;i<=attempts;i++)); do
    if nc -z "$host" "$port" >/dev/null 2>&1; then
      return 0
    fi
    sleep "$sleep_s"
  done
  return 1
}

retry_cmd() {
  local attempts="$1"; shift
  local delay="$1"; shift
  local cmd=("$@")
  local i
  for ((i=1;i<=attempts;i++)); do
    if "${cmd[@]}"; then
      return 0
    fi
    echo "[retry] Attempt $i failed, retrying in ${delay}s..." >&2
    sleep "$delay"
  done
  echo "[retry] All attempts failed" >&2
  return 1
}
