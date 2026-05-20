# Fleet Endpoints — Source of Truth

**Last verified:** 2026-05-20  
**Scope:** All infrastructure endpoints for Jarvis ecosystem (LLM, CouchDB LiveSync, Paperless, relay broker, vault)

---

## LLM Endpoints

| Service | Endpoint | Status | Model | Auth | Last Verified | Notes |
|---------|----------|--------|-------|------|----------------|-------|
| Mac mini llama-server | `http://10.10.70.114:8080/v1/chat/completions` | CANONICAL | qwen2.5-7b + voice LoRA | None (LAN, Phase 0) | 2026-05-20 | OpenAI-compatible. Operator: Rocinante. DHCP, no static IP yet (pending PR #638 server-VLAN move). Source: `bin/paperless-retag-via-llm.py`, session logs. |
| Unraid ollama | `http://10.10.70.20:11434` | DEPRECATED | N/A | None | 2026-05-20 | SYCL hardware-capped; won't-fix per proxmox-manager#126. Archive for reference only. |

---

## CouchDB (Obsidian LiveSync)

| Endpoint | Type | Status | Container Host | Last Verified | Notes |
|----------|------|--------|-----------------|----------------|-------|
| `http://10.10.70.20:5984` | LAN HTTP | CANONICAL | Silverwind Unraid @ 10.10.70.20 | 2026-05-20 | Internal Docker container: `obsidian-livesync-couchdb:3.5.1` |
| `https://cdb.terminalgerbil.icu` | WAN HTTPS | CANONICAL | (tunneled) | 2026-05-20 | External tunnel endpoint. Per `~/.obsidian/plugins/obsidian-livesync/data.json` (primary vault config). |

**Admin User:** `obsidian`  
**Password Location:** `/mnt/user/appdata/secrets/.env` (Silverwind) → `COUCHDB_OBSIDIAN_PASSWORD`  
**Container Path:** `/mnt/user/appdata/obsidian-livesync-couchdb` on Silverwind  
**Vault Sync Database:** Suffix `b7e9bb05ce3bdaef` (per 2026-05-18 decision log)  
**Also available:** LiveSync UI under Touch ID on operator's Mac (personal sync point)  
**Source:** `docs/decisions/2026-05-18-deploy-pipeline-jarvis-tpm.md`, `docs/audits/unraid-docker-inventory-2026-05-16.md`

---

## Paperless

| Endpoint | Type | Status | Container Host | Last Verified | Notes |
|----------|------|--------|-----------------|----------------|-------|
| `http://10.10.70.20:8000` | LAN HTTP | CANONICAL | Silverwind Unraid @ 10.10.70.20 | 2026-05-20 | Internal Docker container: `paperless-ngx` |

**API Token:** `c1151d23f99d4dd7ac0355f7ac9c24fc5c018fac` (hardcoded in `bin/paperless-retag-via-llm.py`)  
**⚠️ Security Smell:** Token hardcoded; move to `PAPERLESS_TOKEN` env var per operator decision  
**Integration:** `bin/paperless-retag-via-llm.py` auto-tags unclassified documents via Mac mini LLM endpoint  
**Container Backup:** `/mnt/user/backups/paperless/` (daily 03:00 UTC via cron)  
**Source:** `bin/paperless-retag-via-llm.py` (lines 26–30), session workspace logs

---

## Relay Broker (File-based Message Queue)

| Component | Path | Status | Format | Last Verified | Notes |
|-----------|------|--------|--------|----------------|-------|
| Message queue | `~/.claude/messages/<project>.json` | CANONICAL | JSON + HMAC signature | 2026-05-20 | One file per project (e.g., `jarvis-obsidian.json`, `xbr-analytics.json`). Enables async cross-project work item handoff. |
| Tools | `~/Projects/<project>/.agent/tools/relay.py` | CANONICAL | Python 3 | 2026-05-20 | Send/receive messages. See `relay.py` + `relay-ack.py`. |
| Tools | `~/Projects/<project>/.agent/tools/relay-ack.py` | CANONICAL | Python 3 | 2026-05-20 | Acknowledge/close work items. |
| Protocol | HMAC-256 signed | CANONICAL | Per `relay.py` | 2026-05-20 | All messages signed; no plaintext relay. |

**Use case:** Stack-level cross-project work (e.g., "Etumos/agentic-stack-private handed Jarvis tasks #652, #653 on 2026-05-20T18:41:48Z")  
**Source:** Session context (this task)

---

## Vault Storage

| Vault | Path | Status | Primary | DB Suffix | Last Verified | Notes |
|-------|------|--------|---------|-----------|----------------|-------|
| Jarvis | `/Users/jasonbonito/Vaults/Jarvis/` | CANONICAL | `/Users/jasonbonito/Vaults/Jarvis/` | `b7e9bb05ce3bdaef` | 2026-05-20 | LiveSync syncs to `cdb.terminalgerbil.icu` |
| 01-Human | (in Jarvis) | CANONICAL | Read-only sacred | - | 2026-05-20 | Operator memory, no agent writes. |
| 02-Projects | (in Jarvis) | CANONICAL | Collaborative | - | 2026-05-20 | Project notes, shared context. |
| 03-Agent | (in Jarvis) | CANONICAL | Autonomous | - | 2026-05-20 | Agent working memory, decisions, spikes. |

**LiveSync configured in:** `~/.obsidian/plugins/obsidian-livesync/data.json` (per decision 2026-05-18)  
**Source:** `docs/decisions/2026-05-18-deploy-pipeline-jarvis-tpm.md`, vault configuration audit

---

## Postgres (xbr-analytics)

| Component | Status | Last Verified | Notes |
|-----------|--------|----------------|-------|
| xbr-analytics Postgres | TBD | 2026-05-20 | Check xbr-analytics' `AGENTS.project.md` for connection string + schema. |

**How to find:** If `AGENTS.project.md` not in xbr-analytics, file xbr-analytics#TBD to surface this gap.

---

## Cross-References

- **Infra decisions:** See `docs/decisions/2026-05-18-deploy-pipeline-jarvis-tpm.md` (CouchDB, LiveSync)
- **Hardware deprecation:** See proxmox-manager#126 (Unraid ollama deprecation)
- **Server VLAN move:** See proxmox-manager#638 (Mac mini static IP)
- **Operator secrets:** See `/mnt/user/appdata/secrets/.env` on Silverwind (credentials management)
- **Fleet conventions:** See `docs/canonical/fleet-conventions.md` (ticket filing for infra work)
- **Original draft:** Etumos/jarvis-obsidian PR #256 (merged 2026-05-20, homed here per operator decision)

---

## Operator Maintenance Checklist

- [ ] Verify Mac mini llama-server is reachable (`curl http://10.10.70.114:8080/health`)
- [ ] Test CouchDB LAN endpoint (`curl http://10.10.70.20:5984/`)
- [ ] Test CouchDB WAN endpoint (`curl https://cdb.terminalgerbil.icu/`)
- [ ] Verify Paperless reachable (`curl http://10.10.70.20:8000/`)
- [ ] Check Paperless token is **not** hardcoded in production (security smell flagged)
- [ ] Verify relay broker messages exist in `~/.claude/messages/` (spot-check)
- [ ] Confirm Vault syncs to CouchDB (last sync timestamp in Obsidian UI)
