# Recovering a Dirty Working Tree

**Scope:** Fleet-wide runbook for sequencing git cleanup when a working tree spans multiple change classes.

**Source authority:** li-ssi-bot#96 (2026-05-20) — canonical dirty-tree recovery incident that produced this doc.

---

## Overview

A dirty working tree spanning stack churn, product state, runtime tools, and build artifacts must be cleaned in order — the wrong sequence discards real state or breaks the next session.

---

## Change Groups

| Group | Contents | Action |
|-------|----------|--------|
| **A** | Product / operational state (real, committed intent) | Keep — commit atomically |
| **B** | Fleet config mutations (R32 frontmatter, etc.) | Commit on `main`, not feature branch |
| **C** | Stack churn (`~80 .agent/` + settings files) — runtime mutations | Archive branch or revert |
| **D** | Build artifacts (untracked dirs, cache) | `.gitignore` + `git clean` |

---

## Carve-outs from Group A (.agent/ runtime mutations)

**These files MUST NOT be stashed, archived, or reverted as part of a Group C cleanup**, even if they appear in the `.agent/` tree alongside stack churn:

| File | Why |
|------|-----|
| `.agent/tools/relay-ack.py` | Required to ack inbox messages — archiving causes mid-session ack failure |
| `.agent/tools/relay.py` | Core relay send/receive — absent = all cross-project handoffs break |
| `.agent/tools/_identity.py` | Session identity token used by relay signing — absent = HMAC failures |
| `.agent/tools/recall.py` | Memory retrieval at every action gate — absent = recall.py lookups fail silently |
| `.agent/tools/learn.py` | Rule ingestion tool — absent = `learn.py` calls throw at command start |
| `.agent/tools/show.py` | Brain state introspection — absent = `show.py` is missing, confusing |
| **Any `.agent/tools/*.py`** | **Rule:** tools are code, not data. Never archive code into a side branch. |

**Failure mode documented in li-ssi-bot#96:** `relay-ack.py` and `_identity.py` were committed to `archive/stack-churn-pre-cleanup-*`, leaving the working tree without them. The next session attempted inbox ack, got `FileNotFoundError`, and recovered via `git checkout archive/ -- .agent/tools/relay-ack.py .agent/tools/_identity.py`.

---

## Pre-flight Check (before any Group C cleanup)

Run this before reverting or archiving `.agent/` contents:

```bash
# Count runtime tools on origin/main
ORIGIN_COUNT=$(git show origin/main:.agent/tools | grep -c '\.py$' 2>/dev/null || echo 0)

# Count runtime tools in working tree
WORKING_COUNT=$(find .agent/tools -name '*.py' -type f | wc -l | tr -d ' ')

echo "origin/main tool count: $ORIGIN_COUNT"
echo "working tree tool count: $WORKING_COUNT"
```

If `WORKING_COUNT < ORIGIN_COUNT` after cleanup: a required tool was lost. Recover with:
```bash
git checkout origin/main -- .agent/tools/
```

If `WORKING_COUNT > ORIGIN_COUNT` after cleanup: new tools exist in the working tree that were authored this session — they are intentional, not churn, and should NOT be reverted.

---

## Sequence

### Step 0 — DO NOT force-merge or `git checkout` to main yet

That discards uncommitted changes. Categorize first.

### Step 1 — Run the pre-flight check

Record the origin/main tool count. Hold it as baseline.

### Step 2 — Archive Group C (stack churn only — excluding .agent/tools/*.py)

```bash
# Identify the churn files (manifests, hooks, skills, memory candidates)
# DO NOT include .agent/tools/*.py in this add
git checkout -b archive/stack-churn-pre-cleanup-$(date +%Y-%m-%d)
git add .agent/skills/ .agent/hooks/ .agent/memory/ .agent/harness/ .claude/settings.json
# Verify no .agent/tools/*.py are staged:
git diff --cached --name-only | grep 'agent/tools/.*\.py' && echo "STOP: runtime tools staged — unstage before continuing"
git commit -m "archive: stack churn snapshot pre-cleanup $(date +%Y-%m-%d) (runtime tools excluded)"
git checkout -  # back to your working branch
```

### Step 3 — Commit Group A (product/operational state)

```bash
git add <product-files>
git commit -m "fix: <describe recovery>"
```

### Step 4 — Commit Group B (fleet config on main)

```bash
git stash   # stash any remaining noise
git checkout main
git stash pop
git add AGENTS.project.md  # or whatever fleet config changed
git commit -m "chore: <fleet config change>"
```

### Step 5 — Handle Group D (build artifacts)

```bash
echo ".playwright-mcp/" >> .gitignore
echo ".agent/.cache/" >> .gitignore
git rm -r --cached .playwright-mcp/ .agent/.cache/ 2>/dev/null || true
git add .gitignore
git commit -m "chore: gitignore build artifacts"
```

### Step 6 — Run post-cleanup pre-flight check

```bash
WORKING_COUNT_AFTER=$(find .agent/tools -name '*.py' -type f | wc -l | tr -d ' ')
echo "After cleanup: $WORKING_COUNT_AFTER tools (origin had $ORIGIN_COUNT)"
# WORKING_COUNT_AFTER should be >= ORIGIN_COUNT
```

If below baseline: `git checkout origin/main -- .agent/tools/` before proceeding.

---

## Branch Staleness Assessment

After cleanup, if the feature branch has no `src/` changes:

```bash
git log --oneline main -- src/ | head -10
```

- If recent commits touch `src/`: work landed elsewhere — branch is stale, abandon it.
- If no recent `src/` commits: punch list is still pending, branch is live.

---

## Related

- li-ssi-bot#96 — originating incident (dirty tree spanning 4 groups, runtime tool ack failure)
- agentic-stack-private#700 — tracking ticket for this runbook
- `.agent/tools/relay-ack.py`, `.agent/tools/_identity.py` — runtime-critical files
