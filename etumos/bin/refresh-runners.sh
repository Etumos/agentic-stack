#!/bin/bash
# etumos/bin/refresh-runners.sh
#
# Auto-recovery for self-hosted GHA runners using ACCESS_TOKEN-based registration.
# Detects offline / missing runners via gh API and `docker compose restart`s
# them. Container's entrypoint reads ACCESS_TOKEN (a long-lived PAT) and
# self-registers on the way up.
#
# This pattern requires runners configured with `ACCESS_TOKEN: ${GITHUB_TOKEN}`
# in their compose service (NOT per-runner RUNNER_TOKEN env files). See
# etumos/compose-snippets/gha-runner-access-token.yml for the canonical block.
#
# Reads from .etumos.config.sh: CANONICAL_HOST, COMPOSE_DIR, GHA_REPOS array.
# Requires: gh CLI authenticated with `repo` scope.
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
[ -f "$ROOT/.etumos.config.sh" ] && source "$ROOT/.etumos.config.sh"

CANONICAL_HOST="${CANONICAL_HOST:?set in .etumos.config.sh}"
COMPOSE_DIR="${COMPOSE_DIR:?set in .etumos.config.sh}"

# RUNNERS array: each entry is "runner-name:compose-service:repo"
# Override via .etumos.config.sh; default reads $RUNNERS if defined.
if [ -z "${RUNNERS+x}" ]; then
  echo "ERROR: RUNNERS array not set in .etumos.config.sh" >&2
  echo "  example:" >&2
  echo "    RUNNERS=(" >&2
  echo "      \"unraid-1:gha-runner:Etumos/myproject\"" >&2
  echo "      \"unraid-2:gha-runner-2:Etumos/myproject\"" >&2
  echo "    )" >&2
  exit 1
fi

ts() { date '+%Y-%m-%dT%H:%M:%S'; }
log() { echo "[$(ts)] $*"; }

CACHE_DIR=$(mktemp -d)
trap 'rm -rf "$CACHE_DIR"' EXIT

get_status_for_repo() {
  local repo="$1"
  local cache_file="$CACHE_DIR/$(echo "$repo" | tr '/' '_').cache"
  if [[ ! -f "$cache_file" ]]; then
    gh api "/repos/$repo/actions/runners" --jq '.runners[] | "\(.name)\t\(.status)"' > "$cache_file" 2>/dev/null || echo "" > "$cache_file"
  fi
  cat "$cache_file"
}

refresh_runner() {
  local name="$1" service="$2"
  log "restarting service: $service (will self-register via ACCESS_TOKEN)"
  ssh "$CANONICAL_HOST" "cd $COMPOSE_DIR && docker compose --profile runner restart $service" > /dev/null
  log "$name restarted"
}

log "=== runner health check ==="
need_refresh=0

for entry in "${RUNNERS[@]}"; do
  IFS=':' read -r name service repo <<< "$entry"
  status=$(get_status_for_repo "$repo" | awk -F'\t' -v n="$name" '$1==n {print $2}')
  if [[ -z "$status" ]]; then
    log "$name: MISSING — restarting"
    refresh_runner "$name" "$service"
    need_refresh=$((need_refresh + 1))
  elif [[ "$status" != "online" ]]; then
    log "$name: $status — restarting"
    refresh_runner "$name" "$service"
    need_refresh=$((need_refresh + 1))
  else
    log "$name: online"
  fi
done

log "=== complete: $need_refresh refreshed ==="
