# Fleet Conventions — Ticket Creation & Labeling

**Last verified:** 2026-05-20  
**Scope:** Cross-project issue/PR filing, label semantics, ADR conventions for Jarvis ecosystem

---

## Default Target Repo Decision Tree

When filing a new issue:

```
Does the work affect multiple projects or the shared stack?
├─ YES → <private-stack-repo> (stack-level concerns, shared infra, contracts)
│        Examples: cross-project relay protocol, fleet endpoint changes, shared memory conventions
└─ NO
   ├─ Is it jarvis-obsidian work?
   │  └─ YES → <jarvis-project>
   │           Examples: vault sync, operator scripts, agent learnings
   │
   ├─ Is it analytics work?
   │  └─ YES → <analytics-project>
   │           Examples: analytics pipeline, BI dashboard, data schema
   │
   ├─ Is it dashboard-template work?
   │  └─ YES → <dashboard-template-project>
   │           Examples: dashboard UI, customer tenant onboarding, template refactor
   │
   ├─ Is it SEO agent work?
   │  └─ YES → <seo-agent-project>
   │           Examples: tenant routing, SEO scoring, brand-specific logic
   │
   ├─ Is it infrastructure/host work?
   │  └─ YES → Etumos/proxmox-manager
   │           Examples: VM provisioning, Unraid→Proxmox migration, networking
   │
   └─ Is it GitHub Actions CI/CD?
      └─ In project X repo (self-hosted runner patterns are project-scoped)
```

**Key principle:** If uncertain, file in the private stack repo with a "follows-to: <project>" label or comment linking the follow-on. Stack maintainer will triage.

---

## Valid Labels by Repository

### Private stack repo

| Label | Semantics | Examples |
|-------|-----------|----------|
| `bug` | Something isn't working | Relay protocol parsing failure, LLM endpoint timeout |
| `documentation` | Improvements or additions to documentation | Add runbook, update CLAUDE.md, clarify contract |
| `enhancement` | New feature or request | New relay message type, memory schema extension |
| `research-spike` | Time-boxed investigation; outcome is a decision/PR, not direct code | "Should we adopt Anthropic Structured Outputs?", "Evaluate CouchDB → PostgreSQL" |
| `agent-autonomous` | Safe for autonomous agent work — see runbook | Pre-approved for agent unilateral action within scope |
| `security` | Security concern or fix | Hardcoded token, TLS migration, access control |
| `infrastructure` | Host, network, storage, backup infra | Fleet endpoint changes, CouchDB setup, storage pool expansion |
| `spike` | Time-boxed investigation → decision/ADR | General research not scoped as `research-spike` |
| `convention` | Conventions, standards, protocols | Label semantics (this doc), ticket templates, naming |
| `fleet` | Fleet-wide tooling or policy | Relay broker changes, endpoint registry, operator runbooks |
| `architecture` | Architectural decision or review | Memory system design, contract shape, cross-project boundaries |
| `tech-debt` | Technical debt or cleanup | Refactor memory tools, migrate from lessons.jsonl → DB |
| `blocked` | Blocked waiting on dependency | Blocked by proxmox-manager#638 (server VLAN move) |
| `deferred` | Parked until external exposure warrants it | Revisit in Q3 2026 |
| `chore` | Routine maintenance | Bump versions, CI config update |
| `anchor-do-not-close` | Permanent reference/anchor ticket — never auto-close | Core contract specs, foundational decisions |

---

### Jarvis project

| Label | Semantics | When to use |
|-------|-----------|-------------|
| `bug` | Something isn't working | Vault sync failure, LLM endpoint down, script broken |
| `documentation` | Improvements or additions to documentation | Update AGENTS.project.md, add runbook, clarify memory conventions |
| `research-spike` | Time-boxed investigation for Jarvis to research and close | "Is LiveSync performance acceptable at scale?" |
| `agentic-stack` | Follow-on work targets this project | Filed in stack-private; this is a dependent sub-issue |
| `human-input` | Blocked on human decision or action | Awaiting operator decision on memory archival strategy |
| `needs-human-decision` | Auto-research ADR drafted — awaiting human adopt/skip/defer decision | Agent filed spike; operator must decide |
| `status:accepted` | Owner has verdict + execution sub-issue filed | Ready to work |
| `log` | Logging or observability work | Add structured logging to relay, improve audit trails |
| `memory` | Agent memory system work | Lessons, semantic/episodic consolidation, recall tooling |
| `meta` | Meta-work about the project structure itself | Update AGENTS.project.md, refactor .agent/ directory |
| `ops` | Operational work | Operator scripts, backup verification, manual maintenance tasks |

---

### Analytics project

| Label | Semantics | When to use |
|-------|-----------|-------------|
| `bug`, `documentation`, `enhancement` | Standard GitHub | |
| `feature` | New functionality or improvement | New analytics metric, tenant dashboard feature |
| `agent-autonomous` | Safe for autonomous agent work — see runbook | Pre-approved for agent changes within scope |
| `investigation` | Diagnostic work (not a full spike) | Debug slow query, investigate test flakiness |
| `human-input` | Blocked on human decision or action | Awaiting product/analyst decision on metric definition |
| `status:proposed` | Spike filed; no owner verdict yet | Initial research ticket |
| `status:accepted` | Owner has verdict + execution sub-issue filed | Ready to execute |
| `status:researching` | Auto-research worker or human is drafting an ADR | In-progress research |
| `status:awaiting-owner` | ADR posted; owner project should respond | Blocked on another team's decision |
| `status:deferred` | Owner says "not now" with trigger condition | Parked until Q3 / until customer asks |
| `status:executing` | Sub-issues in flight | Active work stream |
| `status:done` | All sub-issues closed; spike can close | Ready to merge and close |
| `sev:0`, `sev:1`, `sev:2`, `sev:3` | Severity levels (0=critical, 3=backlog) | Immediate/4h/session/backlog priority |
| `release-blocker:tenant-2` | Must-resolve before next tenant onboarding | Critical path blocker |
| `infrastructure` | Host, network, storage, backup infra | Database migration, deployment infra |
| `migration` | Unraid→Proxmox migration work | VM provisioning, data migration |
| `audit` | Audit ticket or response | Compliance check, security audit |

---

### Dashboard template project

| Label | Semantics | When to use |
|-------|-----------|-------------|
| `bug`, `documentation`, `enhancement` | Standard GitHub | |
| `research-spike` | Time-boxed investigation; outcome is a decision/PR | "Should we migrate to React 19?" |
| `agent-autonomous` | Safe for autonomous agent work — see runbook | Pre-approved changes |
| `investigation` | Diagnostic work | Debug performance regression, investigate error |
| `human-input` | Blocked on human decision or action | Awaiting design/product decision |
| `sev:0`, `sev:1`, `sev:2`, `sev:3` | Severity levels | |
| `release-blocker:tenant-2` | Must-resolve before next customer onboarding | Critical path blocker |
| `blocked` | Blocked waiting on dependency | Blocked on dependency |
| `infra` | Infrastructure or platform | CI/CD pipeline, deployment tooling |
| `security` | Security concern or fix | XSS vulnerability, auth bypass |
| `agent` | Agent-related work or filed by agent | Agent-filed ticket or work on agent integration |
| `automation` | CI/CD or background automation | GitHub Actions workflow, scheduled jobs |
| `docs` | Documentation | User guide, API docs, runbook |
| `hygiene` | Repo hygiene / cleanup | Lint rules, dependency audit |
| `needs-human-decision` | Surfaces in daily Needs-your-input. Decision needed before progress. | Awaiting human design decision |

---

### SEO agent project

| Label | Semantics | When to use |
|-------|-----------|-------------|
| `agent-autonomous` | Safe for autonomous agent work | Pre-approved changes within scope |
| `human-input` | Blocked on human decision | Awaiting decision |
| `status:*` | Status workflow (`proposed`, `researching`, `accepted`, `executing`, `deferred`, `done`) | Use consistently |
| `sev:0`, `sev:1`, `sev:2`, `sev:3` | Severity levels | Priority signaling |
| `brand:c76`, `brand:xbr`, `brand:whwc` | Tenant/brand scoping | Brand-specific work items |
| `audit` | Audit ticket or response | Compliance or security audit |
| `migration` | Unraid→Proxmox migration work | VM provisioning, data migration |
| `blocked` | Blocked waiting on dependency | Blocked by another ticket |
| `infra` | Infrastructure or platform | Deployment, infrastructure changes |
| `security` | Security concern or fix | Auth issue, data exposure |

---

### Etumos/proxmox-manager

| Label | Semantics | When to use |
|-------|-----------|-------------|
| `agent-autonomous` | Safe for autonomous agent work | Pre-approved changes within scope |
| `spike` | Time-boxed investigation → decision/ADR | "Should we adopt Terraform?" |
| `epic` | Tracking/parent issue | Unraid→Proxmox migration, storage pool upgrade |
| `infrastructure` | Host, network, storage, backup infra | VM provisioning, networking, backup strategy |
| `migration` | Unraid→Proxmox migration work | VM move, data migration, decommission Unraid |
| `human-input` | Blocked on human decision | Awaiting operator decision |
| `security` | Security concern or fix | Access control, TLS/cert renewal |
| `status:*` | Status workflow (proposed, researching, accepted, executing, deferred, done) | Use consistently |
| `sev:0`, `sev:1`, `sev:2`, `sev:3` | Severity levels | Priority signaling |
| `hardware` | Hardware-related | New NIC, RAM upgrade, disk replacement |
| `runbook` | Runbook or operational procedure | Backup runbook, failover procedure |
| `deferred` | Parked until external exposure warrants it | Revisit in Q3 when migration completes |

---

## Required Label Patterns per Ticket Type

| Type | Required Labels | Examples |
|------|-----------------|----------|
| **Bug** | `bug` + severity (`sev:0` if critical) | `bug`, `sev:2` |
| **ADR / Spec** | `enhancement` or `spike` + `status:proposed` | Stack-level decision → `enhancement`, `status:proposed` |
| **Spike (research-only)** | `research-spike` or `spike` | Time-boxed research, decision expected |
| **Security Finding** | `security` (where label exists) + severity | `security`, `sev:0` or `sev:1` |
| **Operator-blocked** | `human-input` or `needs-human-decision` | Waiting for operator decision |
| **Cross-project impact** | Project labels | File in primary repo + label links to dependents |

---

## File Naming Conventions

### ADR (Architectural Decision Record)

```
docs/decisions/YYYY-MM-DD-<slug>.md
```

**Example:** `docs/decisions/YYYY-MM-DD-<slug>.md`

**Frontmatter (optional but recommended):**
```markdown
---
date: YYYY-MM-DD
author: <GitHub username>
status: accepted  # accepted | proposed | superseded | archived
relates-to:
  - ../<other-decision>.md
supersedes:
  - ../<old-decision>.md
---
```

### Spec (Feature Specification)

```
docs/specs/YYYY-MM-DD-<slug>.md
```

**Frontmatter:**
```markdown
---
date: YYYY-MM-DD
author: <GitHub username>
epic: <issue-number>  # if part of larger epic
relates-to:
  - ../decisions/<decision-name>.md
---
```

### Spike (Research / Investigation)

```
docs/spikes/YYYY-MM-DD-<slug>.md  (or under decisions/ if outcome is an ADR)
```

---

## Frontmatter Conventions

All decision/spec/spike documents should include:

```yaml
---
date: YYYY-MM-DD
author: <GitHub username>
status: proposed | accepted | superseded | archived | done
relates-to:
  - path/to/related.md
supersedes:
  - path/to/old.md
contradicts:
  - path/to/opposite.md  # only if directly opposed; highlight in the doc
last-verified: YYYY-MM-DD  # update when confirming facts still hold
---
```

**Memory integration:** If a decision is significant (cross-project impact, established a new convention, or caused a rollback), log it:
```bash
python3 .agent/tools/memory_reflect.py "Decided: <summary>" --category architectural
```

---

## Cross-References

- **Stack contract specs:** Private stack repo → `docs/canonical/CONTRACTS.md` (if not present, request via issue)
- **Fleet endpoints:** See `docs/canonical/fleet-endpoints.md` (this repo)
- **Memory conventions:** See `.agent/AGENTS.md` + `CLAUDE.md` in each project
- **CI/CD runbooks:** See project-specific `docs/runbooks/` + shared `~/Projects/agentic-stack/docs/runbooks/`
- **Original draft:** Internal PR (merged 2026-05-20, homed here per operator decision)

---

## Operator Checklist for Filing Issues

- [ ] Is the work stack-level (affects multiple projects) or single-project?
  - Stack-level → private stack repo
  - Single-project → that project's repo
- [ ] Are the required labels present? (See "Required Label Patterns" table)
- [ ] For bugs: Include minimal reproducible example (MRE) and error logs
- [ ] For spikes: Specify decision deadline + definition of "done"
- [ ] For cross-project impact: Add labels linking to dependent projects
- [ ] For ADRs: File under `docs/decisions/YYYY-MM-DD-<slug>.md` with frontmatter
- [ ] For security findings: Use `security` label + `sev:0` or `sev:1` label immediately
- [ ] Link to related tickets in description (use GitHub #123 syntax)
