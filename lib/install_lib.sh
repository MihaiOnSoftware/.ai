#!/usr/bin/env bash

set -euo pipefail

# Load required libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/symlink_helpers.sh"
source "$SCRIPT_DIR/paths.sh"

validate_source_dir "$LIB_DIR" "Lib directory"

log_info "Installing lib files..."

create_symlink "$AI_LIB_PATH/logging.sh" "$LIB_DIR/logging.sh"
create_symlink "$AI_LIB_PATH/symlink_helpers.sh" "$LIB_DIR/symlink_helpers.sh"

log_success "✅ Lib installation complete! (Created: $COUNT_CREATED, Correct: $COUNT_CORRECT, Warnings: $COUNT_WARNING)"
