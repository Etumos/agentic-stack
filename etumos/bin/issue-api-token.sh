#!/bin/bash
# etumos/bin/issue-api-token.sh <user-email> <label>
#
# Issue or rotate a Bearer API token for an existing user in the project's
# admin schema. Token is shown ONCE; only its sha256 is stored in the DB.
# Re-run with the same email to rotate (invalidates previous).
#
# Requires the project's User model to have these columns:
#   apiTokenHash      String?   @unique
#   apiTokenLabel     String?
#   apiTokenCreatedAt DateTime?
#   apiTokenLastUsed  DateTime?
#
# And a `getAuthContext(req)` (or equivalent) auth wrapper in the app that
# accepts Bearer <token> and resolves to the matching user. See
# https://github.com/Etumos/agentic-stack/etumos/templates/api-token-auth.md
# for the schema migration + auth wrapper templates.
#
# Reads from .etumos.config.sh: CANONICAL_HOST (postgres host), ADMIN_SCHEMA,
# ADMIN_DB_USER. Override ADMIN_SCHEMA via env for staging/dev variants.
set -e

if [ $# -lt 2 ]; then
  echo "usage: $0 <user-email> <label>"
  echo "  example: $0 agent@system.local agent"
  exit 1
fi

EMAIL="$1"
LABEL="$2"

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
[ -f "$ROOT/.etumos.config.sh" ] && source "$ROOT/.etumos.config.sh"

CANONICAL_HOST="${CANONICAL_HOST:?set in .etumos.config.sh}"
ADMIN_SCHEMA="${ADMIN_SCHEMA:?set in .etumos.config.sh}"
ADMIN_DB_USER="${ADMIN_DB_USER:?set in .etumos.config.sh}"
PG_CONTAINER="${PG_CONTAINER:-postgres-1}"   # name of the postgres container on the host

TOKEN="xbr_$(openssl rand -hex 16)"
HASH=$(printf '%s' "$TOKEN" | shasum -a 256 | awk '{print $1}')

RESULT=$(ssh "$CANONICAL_HOST" "docker exec -i $PG_CONTAINER psql -U $ADMIN_DB_USER -d $ADMIN_DB_USER -t -A -c \"
  UPDATE \\\"$ADMIN_SCHEMA\\\".users
     SET \\\"apiTokenHash\\\"      = '$HASH',
         \\\"apiTokenLabel\\\"     = '$LABEL',
         \\\"apiTokenCreatedAt\\\" = NOW(),
         \\\"apiTokenLastUsed\\\"  = NULL
   WHERE email = '$EMAIL'
   RETURNING id;
\"" 2>/dev/null)

if ! echo "$RESULT" | grep -q '^UPDATE 1$'; then
  echo "ERROR: no user found with email '$EMAIL' in schema '$ADMIN_SCHEMA'." >&2
  exit 1
fi

echo
echo "Token issued for $EMAIL (label: $LABEL):"
echo
echo "  $TOKEN"
echo
echo "Save this token NOW — it will not be shown again. Use as:"
echo "  curl -H 'Authorization: Bearer $TOKEN' ..."
echo
echo "Rotate: re-run this command (invalidates previous)."
echo "Revoke: bin/revoke-api-token.sh $EMAIL"
