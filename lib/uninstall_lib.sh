#!/usr/bin/env bash

set -euo pipefail

# Load required libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/symlink_helpers.sh"
source "$SCRIPT_DIR/paths.sh"

log_info "Uninstalling lib files..."

uninstall_symlink "$AI_LIB_PATH/logging.sh" "$LIB_DIR/logging.sh"
uninstall_symlink "$AI_LIB_PATH/symlink_helpers.sh" "$LIB_DIR/symlink_helpers.sh"

log_success "✅ Lib uninstallation complete!"
