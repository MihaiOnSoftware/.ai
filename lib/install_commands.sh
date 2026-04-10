#!/usr/bin/env bash

set -euo pipefail

# Load required libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/symlink_helpers.sh"
source "$SCRIPT_DIR/paths.sh"

validate_source_dir "$COMMANDS_DIR" "Commands directory"

log_info "Installing commands..."

create_symlink "$CLAUDE_COMMANDS_PATH" "$COMMANDS_DIR"
create_symlink "$OPENCODE_COMMANDS_PATH" "$COMMANDS_DIR"

log_success "✅ Commands installation complete! (Created: $COUNT_CREATED, Correct: $COUNT_CORRECT, Warnings: $COUNT_WARNING)"
