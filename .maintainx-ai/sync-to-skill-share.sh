#!/usr/bin/env bash
set -euo pipefail

# Copy selected local skills into MaintainX/skill-share as real files.
# Usage:
#   .maintainx-ai/sync-to-skill-share.sh [path-to-skill-share]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AI_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DEFAULT_SKILL_SHARE_ROOT="$(cd "$AI_ROOT/../.." && pwd)/MaintainX/skill-share"
SKILL_SHARE_ROOT="${1:-${SKILL_SHARE_ROOT:-$DEFAULT_SKILL_SHARE_ROOT}}"
PLUGIN_SKILLS_DIR="$SKILL_SHARE_ROOT/plugins/mihai.popescu/skills"

SKILLS=(
  adversarial-review
  adversarial-review-loop
  branch-walkthrough
)

if [[ ! -d "$SKILL_SHARE_ROOT/.git" ]]; then
  echo "skill-share repo not found: $SKILL_SHARE_ROOT" >&2
  echo "Pass its path as the first argument or set SKILL_SHARE_ROOT." >&2
  exit 1
fi

mkdir -p "$PLUGIN_SKILLS_DIR"

for skill in "${SKILLS[@]}"; do
  src="$AI_ROOT/skills/$skill/"
  dest="$PLUGIN_SKILLS_DIR/$skill/"

  if [[ ! -d "$src" ]]; then
    echo "missing source skill: $src" >&2
    exit 1
  fi

  rm -rf "$dest"
  mkdir -p "$dest"
  rsync -a --delete "$src" "$dest"
  echo "synced $skill"
done
