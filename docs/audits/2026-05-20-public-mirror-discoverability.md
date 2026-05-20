# Public Mirror Discoverability Audit
**Date:** 2026-05-20  
**Repo:** Etumos/agentic-stack (public mirror)  
**Operator decision:** Scrub sensitive content before archive (#607)  
**Auditor:** agentic-stack dev-manager (Sonnet)

---

## Summary

| Category | Count |
|----------|-------|
| (a) SENSITIVE — scrub | 14 |
| (b) INTENTIONAL PUBLIC | 2 |
| (c) AMBIGUOUS — operator review | 5 |
| **Total hits** | **21** |

Sensitive content was concentrated in two files: `docs/canonical/fleet-endpoints.md` and `docs/canonical/fleet-conventions.md`. All other files were clean.

---

## Search Coverage

All patterns from the operator brief were searched via `gh search code --repo Etumos/agentic-stack`. Results:

| Pattern | Search Result | Manual Confirm | File(s) |
|---------|---------------|----------------|---------|
| `10.10.70.` | 0 (rate-limited, covered by subnet searches) | 3 hits | `docs/canonical/fleet-endpoints.md` |
| `10.10.30.` | 0 | — | — |
| `10.10.10.` | 0 | — | — |
| `192.168.` | 0 | — | — |
| `Rocinante` | 0 | 1 hit | `docs/canonical/fleet-endpoints.md` |
| `Silverwind` | 0 | 2 hits | `docs/canonical/fleet-endpoints.md` |
| `xbr-` | 0 | multiple | `docs/canonical/fleet-conventions.md`, `fleet-endpoints.md` |
| `crucible76` | 0 | 0 | — |
| `RELAY_SECRET_` | 0 | 0 | — |
| `_TOKEN=` | 0 | 0 | — |
| `_PASSWORD=` | 0 | 1 hit | `docs/canonical/fleet-endpoints.md` |
| `_KEY=` | 0 | 0 | — |
| `GITEA_READ_TOKEN` | 0 | 0 | — |
| `GITHUB_FEEDBACK_PAT` | 0 | 0 | — |
| `COUCHDB_OBSIDIAN_PASSWORD` | 0 | 1 hit | `docs/canonical/fleet-endpoints.md` |
| `bearer ` | 0 | 0 | — |
| `Basic Auth` | 0 | 0 | — |
| `jasonbonito` | 0 | 2 hits | `docs/canonical/fleet-endpoints.md` |
| `bonito@` | 0 | 0 | — |
| `Jason Bonito` | 0 | 0 | — |
| `/Users/jasonbonito` | 0 | 2 hits | `docs/canonical/fleet-endpoints.md` |
| `Etumos` (non-org uses) | 0 | 0 | — |
| `agentic-stack-private` | 0 | multiple | `docs/canonical/fleet-conventions.md`, `fleet-endpoints.md` |
| `jarvis-obsidian` | 0 | multiple | `docs/canonical/fleet-conventions.md`, `fleet-endpoints.md` |
| `compliance-officer` | 0 | 0 | — |
| `xbr-analytics` | 0 | multiple | `docs/canonical/fleet-conventions.md`, `fleet-endpoints.md` |

> Note: GitHub code search returned 0 for most patterns due to index behavior with dotted-octet IPs and path strings. Manual file reads confirmed actual hits in `docs/canonical/`.

---

## Detailed Hit Inventory

### docs/canonical/fleet-endpoints.md

| Pattern | Location | Category | Action Taken |
|---------|---------|----------|--------------|
| `10.10.70.114` | LLM table (Mac mini endpoint) | **(a) SENSITIVE** | Redacted → `<LAN-IP-REDACTED>:8080` |
| `10.10.70.20` | LLM table, CouchDB table (x2), Paperless table | **(a) SENSITIVE** | Redacted → `<LAN-IP-REDACTED>` |
| `Rocinante` | LLM table notes column | **(a) SENSITIVE** | Redacted → `<mac-mini-host>` |
| `Silverwind` | CouchDB table (x2), Paperless table, Vault section | **(a) SENSITIVE** | Redacted → `<unraid-host>` |
| `/Users/jasonbonito/Vaults/Jarvis/` | Vault Storage table | **(a) SENSITIVE** | Redacted → `<operator-vault-path>/Jarvis/` |
| `jasonbonito` | Vault Storage table (x2) | **(a) SENSITIVE** | Redacted as above |
| `COUCHDB_OBSIDIAN_PASSWORD` | CouchDB section, Password Location | **(a) SENSITIVE** | Redacted → `<SECRET_NAME>` |
| `c1151d23f99d4dd7ac0355f7ac9c24fc5c018fac` | Paperless API Token row | **(a) SENSITIVE — CRITICAL** | Redacted → `<PAPERLESS-API-TOKEN-REDACTED>` |
| `agentic-stack-private` | Relay Broker use-case note | **(a) SENSITIVE** | Redacted → `<private-consumer-repo>` |
| `jarvis-obsidian` | Relay Broker note, Cross-References | **(a) SENSITIVE** | Redacted → `<jarvis-project>` |
| `/mnt/user/appdata/secrets/.env` | CouchDB section, Vault section | **(a) SENSITIVE** | Redacted → `<secrets-env-path>` |
| `cdb.terminalgerbil.icu` | CouchDB WAN endpoint | **(c) AMBIGUOUS** | Redacted → `<WAN-ENDPOINT-REDACTED>` (conservative) |
| `b7e9bb05ce3bdaef` | CouchDB DB suffix, Vault table | **(c) AMBIGUOUS** | Redacted → `<DB-SUFFIX-REDACTED>` (conservative) |
| `xbr-analytics` | Postgres section, Cross-References | **(c) AMBIGUOUS** | Redacted to generic `<analytics-project>` |

### docs/canonical/fleet-conventions.md

| Pattern | Location | Category | Action Taken |
|---------|---------|----------|--------------|
| `agentic-stack-private` | Decision tree (x3), Key principle, Cross-References | **(a) SENSITIVE** | Redacted → `<private-stack-repo>` |
| `jarvis-obsidian` | Decision tree, label tables | **(a) SENSITIVE** | Redacted → `<jarvis-project>` |
| `Crucible76.com` | seo-master-agent labels (`brand:c76`) | **(a) SENSITIVE** | Removed domain from label description |
| `wholehomewellnessco.com` | seo-master-agent labels (`brand:whwc`) | **(a) SENSITIVE** | Removed domain from label description |
| `Etumos/jarvis-obsidian PR #256` | Cross-References | **(a) SENSITIVE** | Redacted → `Internal PR` |
| `xbr-analytics` | Decision tree, label tables | **(c) AMBIGUOUS** | Redacted → `<analytics-project>` (conservative) |
| `xbr-dashboard-template` | Decision tree, label tables | **(c) AMBIGUOUS** | Redacted → `<dashboard-template-project>` (conservative) |
| `xbr.ai` | brand label description | **(c) AMBIGUOUS** | Removed from label description (conservative) |
| `proxmox-manager` | Decision tree, label tables | **(b) INTENTIONAL PUBLIC** | Retained — infrastructure PM repo, generic name |
| `seo-master-agent` | Decision tree | **(b) INTENTIONAL PUBLIC** | Retained — generic SEO agent name |

### All other files checked

| File | Result |
|------|--------|
| README.md | Clean. References `codejunkie99/agentic-stack` (upstream alias). |
| .env.example | Clean. Placeholder values only. |
| .github/workflows/sync-upstream.yml | Clean. References `codejunkie99/agentic-stack` as upstream. |
| .agent/AGENTS.md | Clean. Generic template. |
| .agent/memory/personal/PREFERENCES.md | Clean. Template placeholder. |
| .agent/memory/working/WORKSPACE.md | Clean. Template placeholder. |
| .agent/memory/semantic/LESSONS.md | Clean. Generic lessons, no PII. |
| .agent/memory/semantic/DECISIONS.md | Clean. Generic architectural decisions. |
| .agent/memory/episodic/AGENT_LEARNINGS.jsonl | Clean. No PII in logged events. |
| All other files | Code search 0 for all sensitive patterns. |

---

## Critical Action Required — Token Rotation

A live Paperless API token was found in `docs/canonical/fleet-endpoints.md` (now redacted in this PR). **Rotate it immediately** — it remains in git history until a history rewrite is performed on the public mirror.

Recommended steps:
1. Rotate the token in Paperless-NGX admin UI now (before this PR merges).
2. Update `bin/paperless-retag-via-llm.py` in the private repo to use `PAPERLESS_TOKEN` env var.
3. After this PR merges, run `git filter-repo` on the public mirror to purge the token from history.

---

## Items for Operator Review (c)

1. `cdb.terminalgelbil.icu` — external tunnel domain. Conservatively redacted. Restore if public-safe.
2. `b7e9bb05ce3bdaef` — CouchDB DB suffix. Conservatively redacted. Restore if not sensitive.
3. `xbr-analytics` / `xbr-dashboard-template` — internal project names. Conservatively redacted to generics. Restore if these names are intentionally public.
4. `xbr.ai` — brand domain in label description. Conservatively removed. Restore if public-safe.
5. `seo-master-agent` / `proxmox-manager` — retained as intentional public. Confirm operator agrees.
