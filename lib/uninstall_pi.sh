#!/usr/bin/env bash

set -euo pipefail

# Load required libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logging.sh"
source "$SCRIPT_DIR/paths.sh"

uninstall_symlink() {
    local target_path="$1"
    local expected_source="$2"

    if [ -e "$target_path" ] || [ -L "$target_path" ]; then
        if [ -L "$target_path" ]; then
            local existing_target
            existing_target="$(readlink "$target_path")"
            if [ "$existing_target" = "$expected_source" ]; then
                rm "$target_path"
                log_success "Removed symlink: $target_path"
            else
                log_warning "Skipping path: Not a symlink to this repo"
                echo "  Path:   $target_path"
                echo "  Points: $existing_target"
                echo "  Expect: $expected_source"
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

log_info "Uninstalling pi integration..."

uninstall_symlink "$PI_SKILLS_PATH" "$SKILLS_DIR"
uninstall_symlink "$PI_AGENTS_PROMPTS_PATH" "$AGENTS_DIR"
uninstall_symlink "$PI_EXTENSION_PATH" "$PI_EXTENSION_SOURCE"

# Update settings.json
log_info "Updating pi settings..."
node "$SCRIPT_DIR/pi_settings.js" uninstall

log_success "✅ Pi uninstallation complete!"
