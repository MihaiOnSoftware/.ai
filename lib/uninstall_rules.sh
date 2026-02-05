#!/usr/bin/env bash

set -euo pipefail

# Load required libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logging.sh"
source "$SCRIPT_DIR/paths.sh"

uninstall_symlink() {
    local target_path="$1"
    local source_dir="$2"

    if [ -e "$target_path" ] || [ -L "$target_path" ]; then
        if [ -L "$target_path" ]; then
            local existing_target
            existing_target="$(readlink "$target_path")"
            if [ "$existing_target" = "$source_dir" ]; then
                rm "$target_path"
                log_success "Removed symlink: $target_path"
            else
                log_warning "Skipping path: Not a symlink to this repo"
                echo "  Path:   $target_path"
                echo "  Points: $existing_target"
                echo "  Expect: $source_dir"
            fi
        else
            log_warning "Skipping path: Not a symlink"
            echo "  Path: $target_path"
        fi
    else
        log_info "Skipping path: Does not exist"
        echo "  Path: $target_path"
    fi
}

log_info "Uninstalling rules..."

uninstall_symlink "$AI_RULES_PATH" "$RULES_DIR"

log_success "✅ Rules uninstallation complete!"
