#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source shared configuration
source "$REPO_ROOT/lib/logging.sh"
source "$REPO_ROOT/lib/paths.sh"

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

echo "=============================="
echo "      Uninstalling...         "
echo "=============================="

# 1. AI Scripts
uninstall_symlink "$AI_SCRIPTS_PATH" "$SCRIPTS_DIR"

# 2. AI Rules
uninstall_symlink "$AI_RULES_PATH" "$RULES_DIR"

# 3. Claude Commands
uninstall_symlink "$CLAUDE_COMMANDS_PATH" "$COMMANDS_DIR"

# 4. Claude Skills
uninstall_symlink "$CLAUDE_SKILLS_PATH" "$SKILLS_DIR"

# 5. Claude Agents
uninstall_symlink "$CLAUDE_AGENTS_PATH" "$AGENTS_DIR"

# 6. Opencode Commands
uninstall_symlink "$OPENCODE_COMMANDS_PATH" "$COMMANDS_DIR"

# 7. Opencode Skills
uninstall_symlink "$OPENCODE_SKILLS_PATH" "$SKILLS_DIR"

# 8. Opencode Agents
uninstall_symlink "$OPENCODE_AGENTS_PATH" "$AGENTS_DIR"

echo ""
log_success "✅ Uninstall complete!"
