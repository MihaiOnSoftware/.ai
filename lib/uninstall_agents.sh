#!/usr/bin/env bash

set -euo pipefail

# Load required libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/symlink_helpers.sh"
source "$SCRIPT_DIR/paths.sh"

log_info "Uninstalling agents..."

uninstall_symlink "$CLAUDE_AGENTS_PATH" "$AGENTS_DIR"
uninstall_symlink "$OPENCODE_AGENTS_PATH" "$AGENTS_DIR"

log_success "✅ Agents uninstallation complete!"
