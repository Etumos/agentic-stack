#!/bin/bash
# bin/update-fork-from-upstream.sh
#
# Pull upstream codejunkie99/agentic-stack changes into this private
# Etumos fork. Idempotent — safe to re-run anytime.
#
# Privacy properties: the `upstream` git remote is configured locally and
# is invisible to GitHub. No fork-relationship is exposed via the API or UI.
# Apache 2.0 imposes no disclosure obligation on private derivative works.
#
# Usage:  bash bin/update-fork-from-upstream.sh
#
# What it does:
#   1. Adds the upstream remote if not present
#   2. Fetches from upstream
#   3. Reports incoming changes
#   4. Fast-forward merges if possible; merge-commits otherwise
#   5. Exits cleanly with diagnostics on conflict
#   6. Pushes to origin (Etumos/agentic-stack) on success
set -euo pipefail

UPSTREAM_URL="https://github.com/Etumos/agentic-stack.git"
UPSTREAM_BRANCH="master"

cd "$(git rev-parse --show-toplevel)"

# 1. Ensure upstream remote exists
if ! git remote get-url upstream &>/dev/null; then
  echo "→ adding upstream remote: $UPSTREAM_URL"
  git remote add upstream "$UPSTREAM_URL"
else
  EXISTING=$(git remote get-url upstream)
  if [ "$EXISTING" != "$UPSTREAM_URL" ]; then
    echo "WARN: upstream remote exists but points elsewhere: $EXISTING"
    echo "      expected: $UPSTREAM_URL"
    echo "      (continuing with existing remote — fix manually if wrong)"
  fi
fi

# 2. Confirm we're on a branch that makes sense to merge into
CURRENT_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "DETACHED")
if [ "$CURRENT_BRANCH" = "DETACHED" ]; then
  echo "ERROR: detached HEAD. Check out a branch first." >&2
  exit 2
fi
if [ -n "$(git status --porcelain)" ]; then
  echo "ERROR: working tree not clean. Commit or stash first." >&2
  git status --short >&2
  exit 2
fi

# 3. Fetch + report
echo "→ fetching upstream/$UPSTREAM_BRANCH ..."
git fetch upstream "$UPSTREAM_BRANCH"

AHEAD=$(git rev-list --count "upstream/$UPSTREAM_BRANCH..HEAD")
BEHIND=$(git rev-list --count "HEAD..upstream/$UPSTREAM_BRANCH")

echo "→ on branch '$CURRENT_BRANCH'"
echo "  ahead of upstream/$UPSTREAM_BRANCH:  $AHEAD"
echo "  behind upstream/$UPSTREAM_BRANCH:    $BEHIND"

if [ "$BEHIND" -eq 0 ]; then
  echo "→ already current with upstream — nothing to do."
  exit 0
fi

echo
echo "→ incoming commits ($BEHIND):"
git log --oneline "HEAD..upstream/$UPSTREAM_BRANCH" | head -20
[ "$BEHIND" -gt 20 ] && echo "  ... ($((BEHIND - 20)) more)"
echo

# 4. Merge — try fast-forward first
if [ "$AHEAD" -eq 0 ]; then
  echo "→ fast-forwarding (no local commits ahead) ..."
  git merge --ff-only "upstream/$UPSTREAM_BRANCH"
else
  echo "→ creating merge commit (local has $AHEAD commit(s) ahead) ..."
  if ! git merge --no-edit "upstream/$UPSTREAM_BRANCH"; then
    echo
    echo "ERROR: merge conflict. Resolve manually:" >&2
    echo "  git status            # see conflicted files" >&2
    echo "  # edit each file, fix conflict markers" >&2
    echo "  git add <files>" >&2
    echo "  git commit            # finalizes the merge" >&2
    echo "  git push origin $CURRENT_BRANCH" >&2
    exit 1
  fi
fi

# 5. Push to origin
echo
echo "→ pushing to origin/$CURRENT_BRANCH ..."
git push origin "$CURRENT_BRANCH"

echo
echo "✓ fork updated to upstream HEAD ($(git rev-parse --short upstream/$UPSTREAM_BRANCH))"
