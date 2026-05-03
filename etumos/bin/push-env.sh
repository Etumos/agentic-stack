#!/bin/bash
# etumos/bin/push-env.sh
#
# Push local .env up to the canonical secrets host. Use ONLY when you've
# rotated a secret locally and need to make it the new canonical. For pull
# (the common case) use bin/sync-env.sh.
#
# Reads CANONICAL_HOST/CANONICAL_PATH/COMPOSE_ENV from .etumos.config.sh.
set -e

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
[ -f "$ROOT/.etumos.config.sh" ] && source "$ROOT/.etumos.config.sh"

CANONICAL_HOST="${CANONICAL_HOST:?set in .etumos.config.sh or env}"
CANONICAL_PATH="${CANONICAL_PATH:?set in .etumos.config.sh or env}"
LOCAL_PATH="${LOCAL_PATH:-$ROOT/.env}"
COMPOSE_ENV="${COMPOSE_ENV:-}"

if [ ! -f "$LOCAL_PATH" ]; then
  echo "ERROR: local .env not found at $LOCAL_PATH" >&2
  exit 1
fi

echo "=== Diff: local vs canonical (key names only — values not shown) ==="
TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT

if scp -q -p "${CANONICAL_HOST}:${CANONICAL_PATH}" "$TMP" 2>/dev/null; then
  if diff -q "$LOCAL_PATH" "$TMP" >/dev/null 2>&1; then
    echo "  no changes — local matches canonical, nothing to push"
    exit 0
  fi
  echo "  changed keys:"
  diff <(grep -oE "^[A-Z_][A-Z_0-9]*" "$LOCAL_PATH" | sort) \
       <(grep -oE "^[A-Z_][A-Z_0-9]*" "$TMP" | sort) | grep -E "^[<>]" | sed 's/^/    /' || true
else
  echo "  (canonical does not exist yet — first push)"
fi

echo
read -p "Proceed with push? [y/N] " confirm
case "$confirm" in
  [yY]|[yY][eE][sS]) ;;
  *) echo "  aborted"; exit 0 ;;
esac

scp -p "$LOCAL_PATH" "${CANONICAL_HOST}:${CANONICAL_PATH}"
ssh "$CANONICAL_HOST" "chmod 600 $CANONICAL_PATH"
echo "  pushed $(grep -cE "^[A-Z_][A-Z_0-9]*=" "$LOCAL_PATH") keys"

if [ -n "$COMPOSE_ENV" ]; then
  echo
  echo "  REMINDER: container-affecting secrets ALSO need to be propagated to:"
  echo "    ${CANONICAL_HOST}:${COMPOSE_ENV}"
  echo "  Then recreate any container that reads them at boot."
fi
