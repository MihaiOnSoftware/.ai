#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/symlink_helpers.sh"
source "$SCRIPT_DIR/paths.sh"

log_info "Uninstalling AGENTS.md..."

uninstall_symlink "$PI_AGENTS_MD_PATH" "$PI_AGENTS_BUILT_PATH"
uninstall_symlink "$CLAUDE_AGENTS_MD_PATH" "$AGENTS_MD_PATH"

log_success "✅ AGENTS.md uninstallation complete!"
