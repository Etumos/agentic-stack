# Fleet Endpoints — Source of Truth

**Last verified:** 2026-05-20  
**Scope:** All infrastructure endpoints for Jarvis ecosystem (LLM, CouchDB LiveSync, Paperless, relay broker, vault)

> **Note:** Sensitive values (IPs, hostnames, credentials, paths) have been redacted from this public mirror. See the private repo for the full source of truth.

---

## LLM Endpoints

| Service | Endpoint | Status | Model | Auth | Last Verified | Notes |
|---------|----------|--------|-------|------|----------------|-------|
| Mac mini llama-server | `http://<LAN-IP-REDACTED>:8080/v1/chat/completions` | CANONICAL | qwen2.5-7b + voice LoRA | None (LAN, Phase 0) | 2026-05-20 | OpenAI-compatible. Operator: `<mac-mini-host>`. DHCP, no static IP yet (pending PR #638 server-VLAN move). Source: `bin/paperless-retag-via-llm.py`, session logs. |
| Unraid ollama | `http://<LAN-IP-REDACTED>:11434` | DEPRECATED | N/A | None | 2026-05-20 | SYCL hardware-capped; won't-fix per proxmox-manager#126. Archive for reference only. |

---

## CouchDB (Obsidian LiveSync)

| Endpoint | Type | Status | Container Host | Last Verified | Notes |
|----------|------|--------|-----------------|----------------|-------|
| `http://<LAN-IP-REDACTED>:5984` | LAN HTTP | CANONICAL | `<unraid-host>` Unraid @ `<LAN-IP-REDACTED>` | 2026-05-20 | Internal Docker container: `obsidian-livesync-couchdb:3.5.1` |
| `https://<WAN-ENDPOINT-REDACTED>` | WAN HTTPS | CANONICAL | (tunneled) | 2026-05-20 | External tunnel endpoint. Per `~/.obsidian/plugins/obsidian-livesync/data.json` (primary vault config). |

**Admin User:** `obsidian`  
**Password Location:** `<secrets-env-path>` (`<unraid-host>`) → `<SECRET_NAME>`  
**Container Path:** `<container-path>` on `<unraid-host>`  
**Vault Sync Database:** `<DB-SUFFIX-REDACTED>` (per 2026-05-18 decision log)  
**Also available:** LiveSync UI under Touch ID on operator's Mac (personal sync point)  
**Source:** `docs/decisions/2026-05-18-deploy-pipeline-jarvis-tpm.md`, `docs/audits/unraid-docker-inventory-2026-05-16.md`

---

## Paperless

| Endpoint | Type | Status | Container Host | Last Verified | Notes |
|----------|------|--------|-----------------|----------------|-------|
| `http://<LAN-IP-REDACTED>:8000` | LAN HTTP | CANONICAL | `<unraid-host>` Unraid @ `<LAN-IP-REDACTED>` | 2026-05-20 | Internal Docker container: `paperless-ngx` |

**API Token:** `<PAPERLESS-API-TOKEN-REDACTED>` — store in `PAPERLESS_TOKEN` env var  
**⚠️ Security Smell:** Token was previously hardcoded; move to `PAPERLESS_TOKEN` env var per operator decision  
**Integration:** `bin/paperless-retag-via-llm.py` auto-tags unclassified documents via Mac mini LLM endpoint  
**Container Backup:** `<backup-path>` (daily 03:00 UTC via cron)  
**Source:** `bin/paperless-retag-via-llm.py` (lines 26–30), session workspace logs

---

## Relay Broker (File-based Message Queue)

| Component | Path | Status | Format | Last Verified | Notes |
|-----------|------|--------|--------|----------------|-------|
| Message queue | `~/.claude/messages/<project>.json` | CANONICAL | JSON + HMAC signature | 2026-05-20 | One file per project. Enables async cross-project work item handoff. |
| Tools | `~/Projects/<project>/.agent/tools/relay.py` | CANONICAL | Python 3 | 2026-05-20 | Send/receive messages. See `relay.py` + `relay-ack.py`. |
| Tools | `~/Projects/<project>/.agent/tools/relay-ack.py` | CANONICAL | Python 3 | 2026-05-20 | Acknowledge/close work items. |
| Protocol | HMAC-256 signed | CANONICAL | Per `relay.py` | 2026-05-20 | All messages signed; no plaintext relay. |

**Use case:** Stack-level cross-project work item handoff between agent projects  
**Source:** Session context (this task)

---

## Vault Storage

| Vault | Path | Status | Primary | DB Suffix | Last Verified | Notes |
|-------|------|--------|---------|-----------|----------------|-------|
| Jarvis | `<operator-vault-path>/Jarvis/` | CANONICAL | `<operator-vault-path>/Jarvis/` | `<DB-SUFFIX-REDACTED>` | 2026-05-20 | LiveSync syncs to WAN CouchDB endpoint |
| 01-Human | (in Jarvis) | CANONICAL | Read-only sacred | - | 2026-05-20 | Operator memory, no agent writes. |
| 02-Projects | (in Jarvis) | CANONICAL | Collaborative | - | 2026-05-20 | Project notes, shared context. |
| 03-Agent | (in Jarvis) | CANONICAL | Autonomous | - | 2026-05-20 | Agent working memory, decisions, spikes. |

**LiveSync configured in:** `~/.obsidian/plugins/obsidian-livesync/data.json` (per decision 2026-05-18)  
**Source:** `docs/decisions/2026-05-18-deploy-pipeline-jarvis-tpm.md`, vault configuration audit

---

## Postgres (analytics)

| Component | Status | Last Verified | Notes |
|-----------|--------|----------------|-------|
| Analytics Postgres | TBD | 2026-05-20 | Check the analytics project's `AGENTS.project.md` for connection string + schema. |

---

## Cross-References

- **Infra decisions:** See `docs/decisions/2026-05-18-deploy-pipeline-jarvis-tpm.md` (CouchDB, LiveSync)
- **Hardware deprecation:** See proxmox-manager#126 (Unraid ollama deprecation)
- **Server VLAN move:** See proxmox-manager#638 (Mac mini static IP)
- **Operator secrets:** Stored in secrets env file on `<unraid-host>` (credentials management)
- **Fleet conventions:** See `docs/canonical/fleet-conventions.md` (ticket filing for infra work)
- **Original draft:** Internal PR (merged 2026-05-20, homed here per operator decision)

---

## Operator Maintenance Checklist

- [ ] Verify Mac mini llama-server is reachable
- [ ] Test CouchDB LAN endpoint
- [ ] Test CouchDB WAN endpoint
- [ ] Verify Paperless reachable
- [ ] Check Paperless token is **not** hardcoded in production (security smell flagged)
- [ ] Verify relay broker messages exist in `~/.claude/messages/` (spot-check)
- [ ] Confirm Vault syncs to CouchDB (last sync timestamp in Obsidian UI)
