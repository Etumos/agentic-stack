# Etumos overlay

Project-bootstrap conventions extracted from xbr-analytics and standardized for reuse across Etumos projects. Sits on top of the upstream `agentic-stack` framework.

## What's here

```
etumos/
├── README.md                          # this file
├── etumos.config.example.sh           # template config — copy to project as .etumos.config.sh
├── bin/
│   ├── sync-env.sh                    # pull canonical .env from secrets host
│   ├── push-env.sh                    # push local .env up to canonical (intentional rotation only)
│   ├── refresh-runners.sh             # GHA runner auto-recovery (ACCESS_TOKEN-based)
│   ├── issue-api-token.sh             # issue/rotate Bearer API token for an admin user
│   └── revoke-api-token.sh            # revoke a Bearer API token
├── compose-snippets/
│   └── gha-runner-access-token.yml    # canonical runner service block (no per-runner env files)
└── templates/                         # (Phase 2 follow-up — promote.template.sh, etc.)
```

## Per-project setup

In a new project root:

```bash
# 1. Copy the config template + customize
cp /path/to/agentic-stack/etumos/etumos.config.example.sh .etumos.config.sh
# Edit values (CANONICAL_HOST, COMPOSE_DIR, ADMIN_SCHEMA, GHA_REPOS, etc.)
echo ".etumos.config.sh" >> .gitignore   # never commit, contains host info

# 2. Symlink the bin scripts into your project's bin/
mkdir -p bin
for f in /path/to/agentic-stack/etumos/bin/*.sh; do
  ln -sf "$f" "bin/$(basename $f)"
done

# 3. Wire ACCESS_TOKEN-based runners (if using GHA self-hosted)
# Copy the gha-runner block from etumos/compose-snippets/ and adapt RUNNER_NAME etc.
```

## Updating from upstream

Run `bash bin/update-fork-from-upstream.sh` from the agentic-stack repo root. Brings in upstream codejunkie99 changes; etumos/ overlay is preserved (it lives in a path upstream doesn't touch).

## Conventions baked in

- **Canonical secrets on Unraid** — single .env at `/mnt/user/appdata/secrets/.env` (mode 600, root-owned). Symlink-style sync to local + COMPOSE_DIR copies. Pattern from xbr-analytics #83 Phase 2A.
- **ACCESS_TOKEN-based GHA runners** — long-lived PAT shared across all runner replicas. No more per-runner RUNNER_TOKEN env files or "regenerate token" recovery dance. Pattern from xbr-analytics #141.
- **Bearer API token auth** — admin app supports session-cookie OR Bearer-token via `getAuthContext(req)` wrapper. Token-acceptable endpoints opted in per-route. Pattern from xbr-analytics #167/#168.
- **bin/ scripts read .etumos.config.sh** for project-specific paths/hosts so scripts are reusable across Etumos projects without forking.

## What's NOT here yet (Phase 2 follow-up)

- `templates/promote.template.sh` — methodical staging→prod flow with gates
- `templates/deploy.template.sh` — Unraid container recreation pattern
- `templates/CLAUDE.md.template` — protocols section + project-instruction skeleton
- `compose-snippets/postgres-many-dbs.yml` — one-Postgres-many-DBs pattern
- `bin/init-project.sh` — bootstrap wizard for spinning up a new Etumos project end-to-end
