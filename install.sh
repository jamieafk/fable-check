#!/usr/bin/env bash
# Installs the fable-check skill into Claude Code and Codex by symlinking the
# skill folder. Re-running is safe; updates to this project propagate instantly.
set -euo pipefail

SKILL_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/skill" && pwd)"
TARGETS=("$HOME/.claude/skills/fable-check" "$HOME/.codex/skills/fable-check")

for target in "${TARGETS[@]}"; do
  mkdir -p "$(dirname "$target")"
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    echo "SKIP  $target exists and is not a symlink — remove it manually if you want fable-check there."
    continue
  fi
  ln -sfn "$SKILL_SRC" "$target"
  echo "OK    $target -> $SKILL_SRC"
done

echo
echo "Verifying setup..."
node "$SKILL_SRC/scripts/fable-check.mjs" setup
