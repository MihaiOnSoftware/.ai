#!/usr/bin/env bash

set -euo pipefail

# Load required libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/symlink_helpers.sh"
source "$SCRIPT_DIR/paths.sh"

log_info "Uninstalling pi integration..."

uninstall_symlink "$PI_SKILLS_PATH" "$SKILLS_DIR"
uninstall_symlink "$PI_AGENTS_PATH" "$AGENTS_DIR"
uninstall_symlink "$PI_EXTENSION_PATH" "$PI_EXTENSION_SOURCE"

log_success "✅ Pi uninstallation complete!"
