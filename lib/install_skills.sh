#!/usr/bin/env bash

set -euo pipefail

# Load required libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logging.sh"
source "$SCRIPT_DIR/paths.sh"

FORCE_FLAG=""
while getopts "f" opt; do
    case $opt in
        f) FORCE_FLAG="-f" ;;
        *) echo "Usage: install_skills.sh [-f]" >&2; exit 1 ;;
    esac
done

# Validate source directory
if [ ! -d "$SKILLS_DIR" ]; then
    log_error "Error: Skills directory not found: $SKILLS_DIR"
    exit 2
fi

# Clean up old symlinks first
"$SCRIPT_DIR/uninstall_skills.sh"

log_info "Installing skills..."

# Claude: symlink each skill individually (Claude Code only looks one level deep)
mkdir -p "$CLAUDE_SKILLS_DIR"
for skill_dir in "$SKILLS_DIR"/*/; do
    [ -d "$skill_dir" ] || continue
    [ -f "$skill_dir/SKILL.md" ] || continue
    skill_name="$(basename "$skill_dir")"
    ln -s "$skill_dir" "$CLAUDE_SKILLS_DIR/$skill_name"
    log_success "  Symlinked: $CLAUDE_SKILLS_DIR/$skill_name"
done

# OpenCode: symlink the whole directory (supports nested namespaces)
mkdir -p "$(dirname "$OPENCODE_SKILLS_PATH")"
ln -s "$SKILLS_DIR" "$OPENCODE_SKILLS_PATH"
log_success "  Symlinked: $OPENCODE_SKILLS_PATH"

log_success "Skills installation complete!"
