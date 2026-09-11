#!/usr/bin/env bash
# install.sh — agentic-stack installer.
#
# Usage:
#   ./install.sh <adapter-name> [target-dir] [--yes|--reconfigure|--force]
#                                                # install one adapter
#   ./install.sh add <adapter-name> [target-dir] # add an adapter to an
#                                                # already-set-up project
#   ./install.sh remove <adapter-name> [target-dir] [--yes]
#                                                # remove an installed adapter
#   ./install.sh doctor [target-dir]             # read-only audit
#   ./install.sh status [target-dir]             # one-screen view
#   ./install.sh manage [target-dir]             # interactive adapter TUI
#   ./install.sh transfer                        # memory transfer wizard
#   ./install.sh update [target-dir] [--dry-run] [--force]
#                                                # refresh stack-managed paths
#                                                # in target from current
#                                                # stack source (#20)
#   ./install.sh force-env [target-dir] [--all] [--dry-run]
#                                                # strip known disqualifier env
#                                                # vars (DISABLE_TELEMETRY,
#                                                # CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC)
#                                                # from .claude/settings.json
#                                                # without a full stack update
#                                                # (#883)
#   ./install.sh                                 # bare: list available adapters
#                                                # (or, if install.json exists,
#                                                # show what's installable)
#
# adapter-name: claude-code | cursor | windsurf | opencode | openclaw |
#               hermes | pi | codex | grok | standalone-python | antigravity
#
# All real logic lives in harness_manager/ (Python). This script is a
# thin dispatcher so install.sh and install.ps1 share one backend.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
export AGENTIC_STACK_ROOT="$HERE"
# Prepend HERE so `python3 -m harness_manager.cli` finds the module
# regardless of which directory the user invoked install.sh from.
export PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}"

# #3213: PYTHONNOUSERSITE (if inherited from a sandboxed/builder shell) makes
# CPython skip ~/.local/lib/pythonX.Y/site-packages entirely, so a newer pip
# --user install (e.g. redis>=5.0) is invisible and the interpreter falls
# back to an older apt/dist-packages copy (redis 4.3.4) with no visible
# error until verify_python_deps() fails downstream. Same host, same
# interpreter binary, different resolved package — purely an inherited-env
# artifact. Unset it unconditionally before invoking the CLI so this script
# always sees the same site-packages ordering an interactive shell does.
unset PYTHONNOUSERSITE

# BEGIN HOME-GUARD (#3213 / attack finding) — see test_3213_install_home_guard.py
# HOME drives site.getusersitepackages() (~/.local/...). If a caller invoked
# this script with HOME unset or pointed at a directory that isn't the
# account's real home (both seen in subagent builder sandboxes), the
# user-site dir that holds newer --user-installed packages can silently
# miss sys.path. Resolve HOME from the password database when it looks
# unusable, so PYTHONNOUSERSITE-adjacent drift can't reintroduce #3213
# through this second path.
#
# "Unusable" covers two distinct cases: (1) HOME unset, or pointed at a
# directory that doesn't exist at all, and (2) HOME pointed at a directory
# that DOES exist but isn't the account home (e.g. HOME=/tmp, seen in
# builder sandboxes) — case (2) previously fell through unhandled because
# `[ ! -d "$HOME" ]` is true only when the directory is absent, not merely
# wrong. Resolve the account home from the password database up front and
# compare against it so both cases repair the same way.
#
# Threat model (PR #3237 attack finding): case (2) used to be waived when
# $HOME already contained a .local/lib/pythonX/site-packages dir — but
# directory *contents* are attacker-forgeable in any world-writable HOME
# (e.g. /tmp, mode 1777), and with PYTHONNOUSERSITE unset that forged dir
# lands on sys.path, giving local code execution on the install path. A
# non-account HOME is therefore kept ONLY with explicit opt-in
# (AGENTIC_STACK_ALLOW_CUSTOM_HOME=1) AND proof it isn't attacker-writable:
# owned by the invoking user and not group- or world-writable.
resolved_home="$(getent passwd "$(id -un)" 2>/dev/null | cut -d: -f6 || true)"
if [ -z "${HOME:-}" ] || [ ! -d "${HOME:-/nonexistent}" ]; then
  if [ -n "$resolved_home" ] && [ -d "$resolved_home" ]; then
    echo "install.sh: HOME='${HOME:-<unset>}' unusable, resolving to account home '$resolved_home'" >&2
    export HOME="$resolved_home"
  fi
elif [ -n "$resolved_home" ] && [ "$HOME" != "$resolved_home" ]; then
  # HOME exists but isn't the account home. Never trust its contents (they
  # can be forged by anyone with write access to the directory) — trust
  # only ownership + permission bits, and only when the caller opted in.
  keep_home=0
  reason=""
  if [ "${AGENTIC_STACK_ALLOW_CUSTOM_HOME:-}" != "1" ]; then
    reason="no AGENTIC_STACK_ALLOW_CUSTOM_HOME=1 opt-in"
  elif [ ! -O "$HOME" ]; then
    reason="HOME not owned by invoking user"
  else
    home_mode="$(stat -c %a "$HOME" 2>/dev/null || true)"
    if [ -z "$home_mode" ]; then
      reason="could not stat HOME permissions"
    else
      # Last two digits are the group/other permission bits. Any write bit
      # there (group-writable, world-writable, or /tmp-style sticky 1777)
      # means someone other than the owner can write into HOME — reject.
      last_two="${home_mode: -2}"
      group_bit="${last_two:0:1}"
      other_bit="${last_two:1:1}"
      if [ $(( group_bit & 2 )) -ne 0 ] || [ $(( other_bit & 2 )) -ne 0 ]; then
        reason="HOME is group- or world-writable (mode $home_mode)"
      else
        keep_home=1
      fi
    fi
  fi

  if [ "$keep_home" = "1" ]; then
    echo "install.sh: HOME='$HOME' kept via AGENTIC_STACK_ALLOW_CUSTOM_HOME=1 (owned by invoking user, mode ${home_mode:-?}, not group/world-writable)" >&2
  else
    echo "install.sh: HOME='$HOME' exists but is not the account home, resolving to '$resolved_home' ($reason)" >&2
    export HOME="$resolved_home"
  fi
fi
# END HOME-GUARD

if ! command -v python3 >/dev/null 2>&1; then
  echo "error: python3 is required but not found on PATH." >&2
  echo "       agentic-stack uses python3 for the installer + brain tooling." >&2
  exit 1
fi

# Hand off to the Python dispatcher. It owns argv parsing, verb routing,
# adapter validation, and onboarding flow.
exec python3 -m harness_manager.cli "$@"
