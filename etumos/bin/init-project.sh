#!/bin/bash
# etumos/bin/init-project.sh <project-dir>
#
# Bootstrap a new Etumos project against the agentic-stack overlay. Creates
# the project's .etumos.config.sh, symlinks bin scripts, and lays down a
# starter CLAUDE.md from the template.
#
# Idempotent: safe to re-run; won't overwrite existing files (asks first).
#
# Usage:
#   bash etumos/bin/init-project.sh /path/to/new-project
#
# Then in the new project:
#   - edit .etumos.config.sh with your CANONICAL_HOST, COMPOSE_DIR, etc.
#   - edit CLAUDE.md project-specific section
#   - cd <project>; agentic-stack claude-code  # install adapter
set -e

if [ $# -lt 1 ]; then
  echo "usage: $0 <project-dir>"
  echo "  example: $0 ~/Projects/myapp"
  exit 1
fi

DEST="$1"
OVERLAY="$(cd "$(dirname "$0")/.." && pwd)"

if [ ! -d "$DEST" ]; then
  echo "ERROR: $DEST does not exist (create the dir first or run from there)" >&2
  exit 1
fi

cd "$DEST"

# 1. Drop the project config template if not present
if [ -f .etumos.config.sh ]; then
  echo "→ .etumos.config.sh already exists — skipping"
else
  cp "$OVERLAY/etumos.config.example.sh" .etumos.config.sh
  echo "→ wrote .etumos.config.sh (edit values before using)"
fi

# 2. Make sure it's gitignored
if [ -f .gitignore ]; then
  if ! grep -q "^\.etumos\.config\.sh$" .gitignore; then
    echo ".etumos.config.sh" >> .gitignore
    echo "→ added .etumos.config.sh to .gitignore"
  fi
else
  echo ".etumos.config.sh" > .gitignore
  echo "→ created .gitignore with .etumos.config.sh"
fi

# 3. Symlink bin scripts (skip if already linked)
mkdir -p bin
linked=0
for src in "$OVERLAY/bin"/*.sh; do
  name=$(basename "$src")
  [ "$name" = "init-project.sh" ] && continue   # don't symlink ourselves
  dst="bin/$name"
  if [ -L "$dst" ] || [ -e "$dst" ]; then
    continue
  fi
  ln -s "$src" "$dst"
  linked=$((linked + 1))
done
echo "→ symlinked $linked bin script(s) (skipped any already present)"

# 4. Drop a starter CLAUDE.md from template if not present
if [ -f CLAUDE.md ]; then
  echo "→ CLAUDE.md already exists — leaving alone (manual merge if you want overlay updates)"
else
  cp "$OVERLAY/templates/CLAUDE.md.template" CLAUDE.md
  # Replace project name placeholder with the directory name
  PROJECT_NAME=$(basename "$DEST")
  sed -i.bak "s/<PROJECT_NAME>/$PROJECT_NAME/g" CLAUDE.md
  rm CLAUDE.md.bak
  echo "→ wrote starter CLAUDE.md from template (project-specific section needs editing)"
fi

echo
echo "✓ Etumos overlay initialized in $DEST"
echo
echo "Next steps:"
echo "  1. Edit $DEST/.etumos.config.sh — set CANONICAL_HOST, COMPOSE_DIR, ADMIN_SCHEMA, GHA_REPOS"
echo "  2. Edit $DEST/CLAUDE.md — fill in the 'Project-specific section'"
echo "  3. From inside $DEST, install the adapter:  agentic-stack claude-code"
echo "  4. Optional: link the brain to your parent .agent/:  python3 .agent/tools/link_parent_brain.py --apply"
