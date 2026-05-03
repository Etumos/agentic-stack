# etumos.config.example.sh
#
# Copy to your project root as .etumos.config.sh (gitignored) and fill in.
# Etumos bin scripts source this file (via `[ -f .etumos.config.sh ] && source ...`)
# to find your canonical secrets host, compose paths, etc.
#
# Each variable below is documented with what consumes it.

# --- Canonical secrets store on Unraid (or wherever your team puts the .env source-of-truth)
# Used by: bin/sync-env.sh, bin/push-env.sh
CANONICAL_HOST="root@10.10.70.20"
CANONICAL_PATH="/mnt/user/appdata/secrets/.env"

# --- COMPOSE_DIR — where docker-compose.yml + .env live for this project on Unraid.
# (Per CLAUDE.md guidance: COMPOSE_DIR is NOT git-managed; the source-of-truth compose.yml
# lives in the repo and gets manually synced to COMPOSE_DIR.)
# Used by: bin/push-env.sh (rotation reminder text), bin/refresh-runners.sh (cd target)
COMPOSE_DIR="/boot/config/plugins/compose.manager/projects/${ETUMOS_PROJECT_NAME:-PROJECT_NAME}"
COMPOSE_ENV="$COMPOSE_DIR/.env"

# --- Project name + admin schema (for issue-api-token.sh and similar admin-app helpers)
# Used by: bin/issue-api-token.sh, bin/revoke-api-token.sh
ADMIN_SCHEMA="${ADMIN_SCHEMA:-PROJECT_admin}"   # e.g. xbr_admin, foo_admin
ADMIN_DB_HOST="$CANONICAL_HOST"                 # usually same as canonical
ADMIN_DB_USER="${ADMIN_DB_USER:-pgsync}"        # PG user with rights to admin schema

# --- GHA runners — repo names this project runs CI for
# Used by: bin/refresh-runners.sh
GHA_REPOS=("Etumos/${ETUMOS_PROJECT_NAME:-PROJECT_NAME}")
