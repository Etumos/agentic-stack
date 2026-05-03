#!/bin/bash
# etumos/bin/sync-env.sh
#
# Pull the canonical .env from the secrets host → local repo .env. Run this:
#   - At session start if you suspect rotation
#   - After bin/push-env.sh to confirm round-trip
#   - When a teammate has changed a secret on the canonical store
#
# Reads CANONICAL_HOST and CANONICAL_PATH from .etumos.config.sh in repo root
# (or override via env vars).
set -e

# Source project config if present
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
[ -f "$ROOT/.etumos.config.sh" ] && source "$ROOT/.etumos.config.sh"

CANONICAL_HOST="${CANONICAL_HOST:?set in .etumos.config.sh or env (e.g. root@1.2.3.4)}"
CANONICAL_PATH="${CANONICAL_PATH:?set in .etumos.config.sh or env (e.g. /mnt/user/appdata/secrets/.env)}"
LOCAL_PATH="${LOCAL_PATH:-$ROOT/.env}"

echo "=== Pulling canonical .env ==="
echo "  source: ${CANONICAL_HOST}:${CANONICAL_PATH}"
echo "  dest:   ${LOCAL_PATH}"

if [ -f "$LOCAL_PATH" ]; then
  cp -p "$LOCAL_PATH" "${LOCAL_PATH}.bak"
  echo "  backup: ${LOCAL_PATH}.bak"
fi

scp -p "${CANONICAL_HOST}:${CANONICAL_PATH}" "$LOCAL_PATH"
echo
echo "  pulled $(grep -cE "^[A-Z_][A-Z_0-9]*=" "$LOCAL_PATH") keys"
echo
echo "  RESTART YOUR DEV SERVER — node holds env in memory."
