#!/usr/bin/env bash

set -euo pipefail

# Load required libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/symlink_helpers.sh"
source "$SCRIPT_DIR/paths.sh"

log_info "Uninstalling scripts..."

uninstall_symlink "$AI_SCRIPTS_PATH" "$SCRIPTS_DIR"

log_success "✅ Scripts uninstallation complete!"
