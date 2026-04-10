#!/usr/bin/env bash

set -euo pipefail

# Load required libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/symlink_helpers.sh"
source "$SCRIPT_DIR/paths.sh"

validate_source_dir "$SCRIPTS_DIR" "Scripts directory"

log_info "Installing scripts..."

create_symlink "$AI_SCRIPTS_PATH" "$SCRIPTS_DIR"

log_success "✅ Scripts installation complete! (Created: $COUNT_CREATED, Correct: $COUNT_CORRECT, Warnings: $COUNT_WARNING)"
