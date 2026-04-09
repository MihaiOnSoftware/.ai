#!/usr/bin/env bash

set -euo pipefail

# Load required libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logging.sh"
source "$SCRIPT_DIR/paths.sh"

log_info "Uninstalling skills..."

# Remove any symlinks pointing into SKILLS_DIR from both Claude and OpenCode locations
for dir in "$CLAUDE_SKILLS_DIR" "$(dirname "$OPENCODE_SKILLS_PATH")"; do
    [ -d "$dir" ] || continue
    for entry in "$dir"/*; do
        [ -L "$entry" ] || continue
        link_target="$(readlink "$entry")"
        case "$link_target" in
            "$SKILLS_DIR"|"$SKILLS_DIR"/*)
                rm "$entry"
                log_success "  Removed symlink: $entry"
                ;;
        esac
    done
done

log_success "Skills uninstallation complete!"
