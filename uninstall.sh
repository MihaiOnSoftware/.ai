#!/usr/bin/env bash

set -euo pipefail

# ANSI Color Codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log_success() {
    echo -e "${GREEN}$1${NC}"
}

log_warning() {
    echo -e "${YELLOW}$1${NC}"
}

log_info() {
    echo -e "${BLUE}$1${NC}"
}

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
AI_SCRIPTS_PATH="${AI_SCRIPTS_PATH:-$HOME/.ai/scripts/generic}"
SCRIPTS_DIR="$REPO_ROOT/scripts"
uninstall_symlink "$AI_SCRIPTS_PATH" "$SCRIPTS_DIR"

# 2. AI Rules
AI_RULES_PATH="${AI_RULES_PATH:-$HOME/.ai/rules}"
RULES_DIR="$REPO_ROOT/rules"
uninstall_symlink "$AI_RULES_PATH" "$RULES_DIR"

# 3. Claude Commands
CLAUDE_COMMANDS_PATH="${CLAUDE_COMMANDS_PATH:-$HOME/.claude/commands/generic}"
COMMANDS_DIR="$REPO_ROOT/commands"
uninstall_symlink "$CLAUDE_COMMANDS_PATH" "$COMMANDS_DIR"

# 4. Claude Skills
CLAUDE_SKILLS_PATH="${CLAUDE_SKILLS_PATH:-$HOME/.claude/skills/generic}"
SKILLS_DIR="$REPO_ROOT/skills"
uninstall_symlink "$CLAUDE_SKILLS_PATH" "$SKILLS_DIR"

# 5. Claude Agents
CLAUDE_AGENTS_PATH="${CLAUDE_AGENTS_PATH:-$HOME/.claude/agents/generic}"
AGENTS_DIR="$REPO_ROOT/agents"
uninstall_symlink "$CLAUDE_AGENTS_PATH" "$AGENTS_DIR"

# 6. Opencode Commands
OPENCODE_COMMANDS_PATH="${OPENCODE_COMMANDS_PATH:-$HOME/.config/opencode/commands/generic}"
uninstall_symlink "$OPENCODE_COMMANDS_PATH" "$COMMANDS_DIR"

# 7. Opencode Skills
OPENCODE_SKILLS_PATH="${OPENCODE_SKILLS_PATH:-$HOME/.config/opencode/skills/generic}"
uninstall_symlink "$OPENCODE_SKILLS_PATH" "$SKILLS_DIR"

# 8. Opencode Agents
OPENCODE_AGENTS_PATH="${OPENCODE_AGENTS_PATH:-$HOME/.config/opencode/agents/generic}"
uninstall_symlink "$OPENCODE_AGENTS_PATH" "$AGENTS_DIR"

echo ""
log_success "✅ Uninstall complete!"
