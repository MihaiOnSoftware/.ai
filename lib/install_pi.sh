#!/usr/bin/env bash

set -euo pipefail

# Load required libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/symlink_helpers.sh"
source "$SCRIPT_DIR/paths.sh"

validate_source_dir "$SKILLS_DIR" "Skills directory"
validate_source_dir "$AGENTS_DIR" "Agents directory"
validate_source_dir "$PI_EXTENSION_SOURCE" "Task tool extension directory"

log_info "Installing pi integration..."

# Symlink skills
create_symlink "$PI_SKILLS_PATH" "$SKILLS_DIR"

# Symlink agents
create_symlink "$PI_AGENTS_PATH" "$AGENTS_DIR"

# Symlink task-tool extension
create_symlink "$PI_EXTENSION_PATH" "$PI_EXTENSION_SOURCE"

log_success "✅ Pi installation complete! (Created: $COUNT_CREATED, Correct: $COUNT_CORRECT, Warnings: $COUNT_WARNING)"
