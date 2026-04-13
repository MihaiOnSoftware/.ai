#!/usr/bin/env bash

set -euo pipefail

# Load required libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/symlink_helpers.sh"
source "$SCRIPT_DIR/paths.sh"

validate_source_dir "$AGENTS_DIR" "Agents directory"

log_info "Installing agents..."

# Claude and OpenCode: symlink the whole directory as a subdirectory
create_symlink "$CLAUDE_AGENTS_PATH" "$AGENTS_DIR"
create_symlink "$OPENCODE_AGENTS_PATH" "$AGENTS_DIR"

# Pi: symlink each agent individually (subagent extension only looks one level deep)
mkdir -p "$PI_AGENTS_DIR"
for agent_file in "$AGENTS_DIR"/*.md; do
    [ -f "$agent_file" ] || continue
    agent_name="$(basename "$agent_file")"
    create_symlink "$PI_AGENTS_DIR/$agent_name" "$agent_file"
done

log_success "✅ Agents installation complete! (Created: $COUNT_CREATED, Correct: $COUNT_CORRECT, Warnings: $COUNT_WARNING)"
