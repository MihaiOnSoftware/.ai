#!/usr/bin/env bash

set -euo pipefail

# Load required libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/symlink_helpers.sh"
source "$SCRIPT_DIR/paths.sh"

validate_source_dir "$AGENTS_DIR" "Agents directory"

log_info "Installing agents..."

# All targets use individual file symlinks
for target_dir in "$CLAUDE_AGENTS_DIR" "$OPENCODE_AGENTS_DIR" "$PI_AGENTS_DIR"; do
    mkdir -p "$target_dir"
    for agent_file in "$AGENTS_DIR"/*.md; do
        [ -f "$agent_file" ] || continue
        agent_name="$(basename "$agent_file")"
        create_symlink "$target_dir/$agent_name" "$agent_file"
    done
done

log_success "✅ Agents installation complete! (Created: $COUNT_CREATED, Correct: $COUNT_CORRECT, Warnings: $COUNT_WARNING)"
