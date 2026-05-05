# Etumos/agentic-stack-private

Private overlay on top of the public agentic-stack mirror. Hosts Etumos-specific extensions (`etumos/` directory) on top of upstream.

## Repo architecture (3-tier)

```
codejunkie99/agentic-stack          (upstream, public)
        │
        │ daily 06:00 UTC, fast-forward auto-merge
        │ via .github/workflows/sync-upstream.yml in the mirror
        ▼
Etumos/agentic-stack                (public mirror — kept clean)
        │
        │ daily 07:00 UTC, opens PR (review + merge)
        │ via .github/workflows/sync-from-mirror.yml in THIS repo
        ▼
Etumos/agentic-stack-private        (THIS repo — etumos/ overlay lives here)
```

## What this gets you

- **Zero-touch upstream tracking**: codejunkie99 ships → public mirror auto-merges in ~24h → PR opens here
- **Review-gated**: nothing lands in this repo without a PR (and visibility into what changed)
- **Conflicts surface explicitly**: PR comment includes a `:warning:` if merge needed manual resolution
- **Privacy preserved**: etumos/ overlay only ever exists in this private repo

## Manual flow (if Actions are paused / for ad-hoc updates)

```bash
bash bin/update-fork-from-upstream.sh
```

Idempotent. Safe to run anytime. Defaults to pulling from the public mirror.

## What lives where

| Repo | Contents | Editable? |
|---|---|---|
| `codejunkie99/agentic-stack` | Upstream framework (`.agent/`, `harness_manager/`, etc.) | Read-only — submit PRs upstream if you want changes there |
| `Etumos/agentic-stack` (public mirror) | Verbatim copy of upstream | **Don't edit** — the workflow expects fast-forward merges only |
| `Etumos/agentic-stack-private` (this) | Upstream + `etumos/` overlay | Yes — etumos/* is your work |

## License

Upstream is Apache 2.0. Etumos additions inherit unless explicitly marked otherwise. Original LICENSE file from upstream stays untouched per Apache 2.0 attribution.
