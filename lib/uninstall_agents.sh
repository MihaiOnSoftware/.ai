#!/usr/bin/env bash

set -euo pipefail

# Load required libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/symlink_helpers.sh"
source "$SCRIPT_DIR/paths.sh"

log_info "Uninstalling agents..."

uninstall_symlink "$CLAUDE_AGENTS_PATH" "$AGENTS_DIR"
uninstall_symlink "$OPENCODE_AGENTS_PATH" "$AGENTS_DIR"

# Pi: remove individual agent symlinks pointing into AGENTS_DIR
if [ -d "$PI_AGENTS_DIR" ]; then
    for entry in "$PI_AGENTS_DIR"/*; do
        [ -L "$entry" ] || continue
        link_target="$(readlink "$entry")"
        case "$link_target" in
            "$AGENTS_DIR"|"$AGENTS_DIR"/*)
                rm "$entry"
                log_info "  Removed symlink: $entry"
                ;;
        esac
    done
fi

log_success "✅ Agents uninstallation complete!"
