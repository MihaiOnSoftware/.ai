#!/usr/bin/env bash

set -euo pipefail

# Load required libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/symlink_helpers.sh"
source "$SCRIPT_DIR/paths.sh"

validate_source_dir "$AGENTS_DIR" "Agents directory"

log_info "Installing agents..."

create_symlink "$CLAUDE_AGENTS_PATH" "$AGENTS_DIR"
create_symlink "$OPENCODE_AGENTS_PATH" "$AGENTS_DIR"

log_success "✅ Agents installation complete! (Created: $COUNT_CREATED, Correct: $COUNT_CORRECT, Warnings: $COUNT_WARNING)"
