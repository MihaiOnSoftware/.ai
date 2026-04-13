#!/usr/bin/env bash

set -euo pipefail

# Load required libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/symlink_helpers.sh"
source "$SCRIPT_DIR/paths.sh"

log_info "Uninstalling agents..."

# Clean up old-style directory symlinks at agents/generic (from before per-file migration)
for old_dir_symlink in "$CLAUDE_AGENTS_DIR/generic" "$OPENCODE_AGENTS_DIR/generic"; do
    if [ -L "$old_dir_symlink" ]; then
        rm "$old_dir_symlink"
        log_info "  Removed old directory symlink: $old_dir_symlink"
    fi
done

# Remove individual agent symlinks pointing into AGENTS_DIR
for target_dir in "$CLAUDE_AGENTS_DIR" "$OPENCODE_AGENTS_DIR" "$PI_AGENTS_DIR"; do
    [ -d "$target_dir" ] || continue
    for entry in "$target_dir"/*; do
        [ -L "$entry" ] || continue
        link_target="$(readlink "$entry")"
        case "$link_target" in
            "$AGENTS_DIR"|"$AGENTS_DIR"/*)
                rm "$entry"
                log_info "  Removed symlink: $entry"
                ;;
        esac
    done
done

log_success "✅ Agents uninstallation complete!"
