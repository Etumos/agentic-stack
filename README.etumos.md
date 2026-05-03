# Etumos/agentic-stack — private fork

Private fork of [`codejunkie99/agentic-stack`](https://github.com/codejunkie99/agentic-stack) (Apache 2.0). Hosts Etumos-specific extensions on top of upstream.

## Privacy stance

This fork is **PRIVATE** with the GitHub fork-relationship link severed (`parent: null`). The upstream remote is configured locally only — invisible to GitHub's API/UI. No GitHub-side activity exposes the fork relationship. Apache 2.0 imposes no disclosure on derivative works that stay private.

## Updating from upstream

```bash
bash bin/update-fork-from-upstream.sh
```

Idempotent. Safe to run anytime. Reports incoming changes, fast-forwards or merge-commits as appropriate, exits cleanly on conflict.

If the script is ever lost, the manual flow is:
```bash
git remote add upstream https://github.com/codejunkie99/agentic-stack.git
git fetch upstream
git merge upstream/master
git push origin master
```

## What lives here

| Origin | What |
|---|---|
| Upstream files | The agentic-stack framework (`.agent/`, `harness_manager/`, `adapters/`, etc.). Treat as read-only — changes go upstream via PR if generally useful. |
| Etumos additions (Phase 2) | `etumos/` directory with bin scripts, promote/deploy templates, compose snippets, project-bootstrap wizard for spinning up new Etumos projects. |

## Day-to-day

- **Framework upgrades on local machines:** flow through `brew upgrade agentic-stack` — does not touch this fork. Brew pulls directly from upstream's tagged releases.
- **Etumos-specific tooling:** lives in this fork's `etumos/` directory. Update with normal git commits.
- **Periodic upstream sync:** run `bin/update-fork-from-upstream.sh` whenever you want to bring in upstream changes (probably monthly, or on-demand when a release ships something you want).

## License

Upstream is Apache 2.0. Etumos additions inherit that license unless explicitly marked otherwise. The original LICENSE file from upstream stays untouched per Apache 2.0 attribution requirements.
