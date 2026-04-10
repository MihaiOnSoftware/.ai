#!/usr/bin/env bash

set -euo pipefail

# Load required libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/symlink_helpers.sh"
source "$SCRIPT_DIR/paths.sh"

log_info "Uninstalling rules..."

uninstall_symlink "$AI_RULES_PATH" "$RULES_DIR"

log_success "✅ Rules uninstallation complete!"
