#!/usr/bin/env bash

set -euo pipefail

FORCE_MODE="false"

# ANSI Color Codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_success() {
    echo -e "${GREEN}$1${NC}"
}

log_warning() {
    echo -e "${YELLOW}$1${NC}" >&2
}

log_error() {
    echo -e "${RED}$1${NC}" >&2
}

log_info() {
    echo -e "${BLUE}$1${NC}"
}

while getopts "f" opt; do
    case $opt in
        f) FORCE_MODE="true" ;;
        *) echo "Usage: install.sh [-f]" >&2; exit 1 ;;
    esac
done


REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

validate_source_directories() {
    local missing_dirs=()
    local required_dirs=(
        "$REPO_ROOT/scripts"
        "$REPO_ROOT/rules"
        "$REPO_ROOT/commands"
        "$REPO_ROOT/skills"
        "$REPO_ROOT/agents"
    )

    for dir in "${required_dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            missing_dirs+=("$dir")
        fi
    done

    if [ ${#missing_dirs[@]} -gt 0 ]; then
        log_error "Error: Missing required source directories:"
        printf '  - %s\n' "${missing_dirs[@]}" >&2
        exit 2
    fi
}

is_correct_symlink() {
    local target_path="$1"
    local source_dir="$2"

    if [ -L "$target_path" ]; then
        existing_target="$(readlink "$target_path")"
        if [ "$existing_target" = "$source_dir" ]; then
            return 0
        fi
    fi
    return 1
}

create_symlink() {
    local target_path="$1"
    local source_dir="$2"
    local force_mode="$3"

    mkdir -p "$(dirname "$target_path")"

    if is_correct_symlink "$target_path" "$source_dir"; then
        log_info "Symlink already exists: $target_path"
        return 0
    fi

    # Safety check: never overwrite regular files/directories
    if [ -e "$target_path" ] && [ ! -L "$target_path" ]; then
        log_error "Error: $target_path exists and is not a symlink"
        exit 1
    fi

    if [ -L "$target_path" ]; then
        if [ "$force_mode" = "true" ]; then
            log_info "Fixing wrong symlink: $target_path"
            rm "$target_path"
        else
            log_warning "Warning: $target_path is a symlink to wrong location"
            log_warning "Use -f flag to fix wrong symlinks"
            exit 1
        fi
    fi

    ln -s "$source_dir" "$target_path"
    log_success "Created symlink: $target_path -> $source_dir"
}

validate_source_directories

AI_SCRIPTS_PATH="${AI_SCRIPTS_PATH:-$HOME/.ai/scripts/generic}"
SCRIPTS_DIR="$REPO_ROOT/scripts"

create_symlink "$AI_SCRIPTS_PATH" "$SCRIPTS_DIR" "$FORCE_MODE"

AI_RULES_PATH="${AI_RULES_PATH:-$HOME/.ai/rules}"
RULES_DIR="$REPO_ROOT/rules"

create_symlink "$AI_RULES_PATH" "$RULES_DIR" "$FORCE_MODE"

CLAUDE_COMMANDS_PATH="${CLAUDE_COMMANDS_PATH:-$HOME/.claude/commands/generic}"
COMMANDS_DIR="$REPO_ROOT/commands"

create_symlink "$CLAUDE_COMMANDS_PATH" "$COMMANDS_DIR" "$FORCE_MODE"

CLAUDE_SKILLS_PATH="${CLAUDE_SKILLS_PATH:-$HOME/.claude/skills/generic}"
SKILLS_DIR="$REPO_ROOT/skills"

create_symlink "$CLAUDE_SKILLS_PATH" "$SKILLS_DIR" "$FORCE_MODE"

CLAUDE_AGENTS_PATH="${CLAUDE_AGENTS_PATH:-$HOME/.claude/agents/generic}"
AGENTS_DIR="$REPO_ROOT/agents"

create_symlink "$CLAUDE_AGENTS_PATH" "$AGENTS_DIR" "$FORCE_MODE"

OPENCODE_COMMANDS_PATH="${OPENCODE_COMMANDS_PATH:-$HOME/.config/opencode/commands/generic}"

create_symlink "$OPENCODE_COMMANDS_PATH" "$COMMANDS_DIR" "$FORCE_MODE"

OPENCODE_SKILLS_PATH="${OPENCODE_SKILLS_PATH:-$HOME/.config/opencode/skills/generic}"

create_symlink "$OPENCODE_SKILLS_PATH" "$SKILLS_DIR" "$FORCE_MODE"

OPENCODE_AGENTS_PATH="${OPENCODE_AGENTS_PATH:-$HOME/.config/opencode/agents/generic}"

create_symlink "$OPENCODE_AGENTS_PATH" "$AGENTS_DIR" "$FORCE_MODE"

echo ""
log_success "✅ Configuration complete! Configured 8 symlinks for scripts, rules, commands, skills, and agents."
