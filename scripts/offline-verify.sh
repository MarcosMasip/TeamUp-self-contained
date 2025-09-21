#!/usr/bin/env bash
set -euo pipefail
# Scan workspace for http/https references that might indicate undeclared external dependencies.
# Excludes: markdown, license, pdf, images, node_modules, target build outputs, comments heuristically.

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo "[offline-verify] Scanning for external URLs..."
# Collect matches
RESULTS=$(grep -RInE "https?://" \
  --exclude-dir=node_modules \
  --exclude-dir=dist \
  --exclude-dir=target \
  --exclude-dir=.git \
  --exclude=*.pdf \
  --exclude=LICENSE \
  || true)

# Filter known safe local dev endpoints (localhost) and mailpit default
FILTERED=$(echo "$RESULTS" | grep -Ev "localhost(:|/)|127.0.0.1|mailpit" || true)

if [ -z "$FILTERED" ]; then
  echo "[offline-verify] PASS: No external URL references detected."
  exit 0
else
  echo "[offline-verify] WARNING: Potential external references found:" >&2
  echo "$FILTERED" >&2
  exit 1
fi
