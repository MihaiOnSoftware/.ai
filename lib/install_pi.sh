#!/usr/bin/env bash

set -euo pipefail

# Load required libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/symlink_helpers.sh"
source "$SCRIPT_DIR/paths.sh"

validate_source_dir "$SKILLS_DIR" "Skills directory"

log_info "Installing pi integration..."

create_symlink "$PI_SKILLS_PATH" "$SKILLS_DIR"

log_success "✅ Pi installation complete! (Created: $COUNT_CREATED, Correct: $COUNT_CORRECT, Warnings: $COUNT_WARNING)"
