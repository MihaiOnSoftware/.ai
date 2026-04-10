#!/usr/bin/env bash

set -euo pipefail

# Load required libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/symlink_helpers.sh"
source "$SCRIPT_DIR/paths.sh"

log_info "Uninstalling commands..."

uninstall_symlink "$CLAUDE_COMMANDS_PATH" "$COMMANDS_DIR"
uninstall_symlink "$OPENCODE_COMMANDS_PATH" "$COMMANDS_DIR"

log_success "✅ Commands uninstallation complete!"
