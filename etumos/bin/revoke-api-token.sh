#!/bin/bash
# etumos/bin/revoke-api-token.sh <user-email>
#
# Revoke the Bearer API token for a user. Subsequent requests with the old
# token return 401. The user can still log in via password (if applicable).
set -e

if [ $# -lt 1 ]; then
  echo "usage: $0 <user-email>"
  exit 1
fi

EMAIL="$1"

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
[ -f "$ROOT/.etumos.config.sh" ] && source "$ROOT/.etumos.config.sh"

CANONICAL_HOST="${CANONICAL_HOST:?set in .etumos.config.sh}"
ADMIN_SCHEMA="${ADMIN_SCHEMA:?set in .etumos.config.sh}"
ADMIN_DB_USER="${ADMIN_DB_USER:?set in .etumos.config.sh}"
PG_CONTAINER="${PG_CONTAINER:-postgres-1}"

RESULT=$(ssh "$CANONICAL_HOST" "docker exec -i $PG_CONTAINER psql -U $ADMIN_DB_USER -d $ADMIN_DB_USER -t -A -c \"
  UPDATE \\\"$ADMIN_SCHEMA\\\".users
     SET \\\"apiTokenHash\\\"      = NULL,
         \\\"apiTokenLabel\\\"     = NULL,
         \\\"apiTokenCreatedAt\\\" = NULL,
         \\\"apiTokenLastUsed\\\"  = NULL
   WHERE email = '$EMAIL'
     AND \\\"apiTokenHash\\\" IS NOT NULL
   RETURNING id;
\"" 2>/dev/null)

if ! echo "$RESULT" | grep -q '^UPDATE 1$'; then
  echo "ERROR: no token to revoke for '$EMAIL' (user may not exist or had no token)." >&2
  exit 1
fi

echo "Revoked API token for $EMAIL."
