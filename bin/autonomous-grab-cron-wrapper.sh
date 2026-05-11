#!/usr/bin/env bash
# Autonomous-grab cron wrapper with ASI02/ASI10 security hardening.
#
# Changes from original:
# - Per-firing scope: --add-dir only for target repo, not all 6 fleet repos
# - Mechanical budget enforcement: daily-budget.json must exist and be valid
# - Environment safeguard: unset PERMISSION_GATE_SKIP_LABELS explicitly
# - Post-run diff summary: sent via ntfy for operator review
# - Checksum verification: prompt file integrity check (ASI01)

set -uo pipefail

CLAUDE_BIN="/opt/homebrew/bin/claude"
PROJECT_DIR="$HOME/Projects/agentic-stack"
PROMPT_FILE="$PROJECT_DIR/bin/autonomous-grab-cron-prompt.md"
LOG_DIR="$HOME/.claude/agentic-stack"
LOG_FILE="$LOG_DIR/cron-history.log"
BUDGET_FILE="$LOG_DIR/daily-budget.json"
TICKETS_INBOX="$PROJECT_DIR/.agent/inbox/agent-autonomous/"

mkdir -p "$LOG_DIR"

ts() { date -u +%Y-%m-%dT%H:%M:%SZ; }

# ASI02/ASI10: UNSET PERMISSION GATE SKIP LABELS
# Prevents selective gate disabling in cron context
unset PERMISSION_GATE_SKIP_LABELS

# Pre-flight checks
if [ ! -x "$CLAUDE_BIN" ]; then
  echo "$(ts) FATAL: claude binary not found at $CLAUDE_BIN" >> "$LOG_FILE"
  exit 1
fi

if [ ! -f "$PROMPT_FILE" ]; then
  echo "$(ts) FATAL: prompt file not found at $PROMPT_FILE" >> "$LOG_FILE"
  exit 1
fi

# ASI01: Verify prompt file integrity
CHECKSUM_FILE="$PROJECT_DIR/bin/autonomous-grab-cron-prompt.md.sha256"
if [ ! -f "$CHECKSUM_FILE" ]; then
  MSG="ABORT: checksum file missing — refusing to invoke Claude"
  echo "$(ts) FATAL: $MSG" >> "$LOG_FILE"
  curl -s -X POST https://ntfy.sh/etumos-alerts -d "$MSG" -H "Title: cron-checksum missing" -H "Priority: urgent" > /dev/null 2>&1 || true
  exit 1
fi

if ! shasum -a 256 -c "$CHECKSUM_FILE" --status 2>/dev/null; then
  MSG="ABORT: prompt file checksum mismatch — file may have been tampered with"
  echo "$(ts) FATAL: $MSG" >> "$LOG_FILE"
  curl -s -X POST https://ntfy.sh/etumos-alerts -d "$MSG" -H "Title: cron-checksum mismatch" -H "Priority: urgent" > /dev/null 2>&1 || true
  exit 1
fi

# ASI02/ASI10: MECHANICAL BUDGET CHECK
# Fail if budget file missing or corrupted (don't treat as unconstrained)
if [ ! -f "$BUDGET_FILE" ]; then
  MSG="ABORT: daily-budget.json missing — refusing unconstrained run"
  echo "$(ts) FATAL: $MSG" >> "$LOG_FILE"
  curl -s -X POST https://ntfy.sh/etumos-alerts -d "$MSG" -H "Title: cron-budget missing" -H "Priority: urgent" > /dev/null 2>&1 || true
  exit 1
fi

# Validate budget JSON is well-formed
if ! command -v jq > /dev/null 2>&1; then
  echo "$(ts) WARNING: jq not found — skipping budget JSON validation" >> "$LOG_FILE"
else
  if ! jq empty "$BUDGET_FILE" 2>/dev/null; then
    MSG="ABORT: daily-budget.json is corrupted — refusing to run"
    echo "$(ts) FATAL: $MSG" >> "$LOG_FILE"
    curl -s -X POST https://ntfy.sh/etumos-alerts -d "$MSG" -H "Title: cron-budget corrupted" -H "Priority: urgent" > /dev/null 2>&1 || true
    exit 1
  fi
fi

# ASI02: DETERMINE TARGET REPO (per-firing scope)
# Query inbox for next agent-autonomous ticket to determine which repo needs work
TARGET_REPO=""
if [ -d "$TICKETS_INBOX" ]; then
  # Look for any .md file; extract repo from GitHub issue URL in metadata
  for ticket in "$TICKETS_INBOX"/*.md; do
    if [ -f "$ticket" ]; then
      # Extract repo owner/name from issue URL
      REPO=$(grep -o 'github.com/Etumos/[^/]*/issues' "$ticket" 2>/dev/null | cut -d/ -f4 | head -1)
      if [ -n "$REPO" ]; then
        TARGET_REPO="$REPO"
        echo "$(ts) Selected target repo: $TARGET_REPO (from ticket: $(basename $ticket))" >> "$LOG_FILE"
        break
      fi
    fi
  done
fi

if [ -z "$TARGET_REPO" ]; then
  echo "$(ts) No agent-autonomous tickets found in inbox; skipping cron firing" >> "$LOG_FILE"
  exit 0
fi

# Validate target repo path exists
TARGET_REPO_PATH="$HOME/Projects/$TARGET_REPO"
if [ ! -d "$TARGET_REPO_PATH/.agent" ]; then
  MSG="ABORT: target repo $TARGET_REPO not found at $TARGET_REPO_PATH"
  echo "$(ts) FATAL: $MSG" >> "$LOG_FILE"
  curl -s -X POST https://ntfy.sh/etumos-alerts -d "$MSG" -H "Title: cron-repo-not-found" -H "Priority: high" > /dev/null 2>&1 || true
  exit 1
fi

echo "$(ts) CRON FIRING — target repo: $TARGET_REPO" >> "$LOG_FILE"

# Run Claude with --add-dir ONLY for target repo (not all 6)
# ASI02/ASI10: Per-firing scope restriction
RUN_LOG="$LOG_DIR/cron-run-$(date +%s).log"
"$CLAUDE_BIN" -p \
  --repo "Etumos/$TARGET_REPO" \
  --add-dir "$TARGET_REPO_PATH" \
  --permission-mode bypassPermissions \
  --model claude-sonnet-4-6 \
  --no-session-persistence \
  "$(cat "$PROMPT_FILE")" \
  > "$RUN_LOG" 2>&1

RUN_EXIT=$?
echo "$(ts) Claude exit code: $RUN_EXIT" >> "$LOG_FILE"

# ASI02/ASI10: POST-RUN DIFF SUMMARY
# Generate git diff for the affected repo and send to ntfy for operator review
if [ $RUN_EXIT -eq 0 ]; then
  if [ -d "$TARGET_REPO_PATH/.git" ]; then
    DIFF_SUMMARY=$(cd "$TARGET_REPO_PATH" && git diff HEAD~1 --stat 2>/dev/null || echo "(no commits since last run)")
    COMMIT_MSG=$(cd "$TARGET_REPO_PATH" && git log -1 --pretty=format:"%s" 2>/dev/null || echo "")
    COMMIT_HASH=$(cd "$TARGET_REPO_PATH" && git log -1 --pretty=format:"%h" 2>/dev/null || echo "")

    NTFY_MSG="Cron firing completed: $TARGET_REPO
Commit: $COMMIT_MSG
Changes:
$DIFF_SUMMARY
Review: $COMMIT_HASH
Log: tail -50 $RUN_LOG"

    curl -s -X POST https://ntfy.sh/etumos-alerts \
      -d "$NTFY_MSG" \
      -H "Title: cron-complete: $TARGET_REPO" \
      -H "Priority: default" \
      > /dev/null 2>&1 || true

    echo "$(ts) Post-run summary sent via ntfy" >> "$LOG_FILE"
  fi
else
  NTFY_MSG="Cron firing FAILED: $TARGET_REPO (exit: $RUN_EXIT)
Check: tail -100 $RUN_LOG"
  curl -s -X POST https://ntfy.sh/etumos-alerts \
    -d "$NTFY_MSG" \
    -H "Title: cron-failed: $TARGET_REPO" \
    -H "Priority: high" \
    > /dev/null 2>&1 || true
fi

echo "$(ts) Cron firing complete" >> "$LOG_FILE"
exit $RUN_EXIT
