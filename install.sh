#!/usr/bin/env bash

set -euo pipefail

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
        echo "Error: Missing required source directories:" >&2
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

    mkdir -p "$(dirname "$target_path")"

    if is_correct_symlink "$target_path" "$source_dir"; then
        echo "Symlink already exists: $target_path"
        return 0
    fi

    if [ -e "$target_path" ] && [ ! -L "$target_path" ]; then
        echo "Error: $target_path exists and is not a symlink" >&2
        exit 1
    fi

    if [ -L "$target_path" ]; then
        echo "Warning: $target_path is a symlink to wrong location" >&2
        echo "Use -f flag to fix wrong symlinks" >&2
        exit 1
    fi

    ln -s "$source_dir" "$target_path"
    echo "Created symlink: $target_path -> $source_dir"
}

validate_source_directories

AI_SCRIPTS_PATH="${AI_SCRIPTS_PATH:-$HOME/.ai/scripts/generic}"
SCRIPTS_DIR="$REPO_ROOT/scripts"

create_symlink "$AI_SCRIPTS_PATH" "$SCRIPTS_DIR"

AI_RULES_PATH="${AI_RULES_PATH:-$HOME/.ai/rules}"
RULES_DIR="$REPO_ROOT/rules"

create_symlink "$AI_RULES_PATH" "$RULES_DIR"

CLAUDE_COMMANDS_PATH="${CLAUDE_COMMANDS_PATH:-$HOME/.claude/commands/generic}"
COMMANDS_DIR="$REPO_ROOT/commands"

create_symlink "$CLAUDE_COMMANDS_PATH" "$COMMANDS_DIR"

CLAUDE_SKILLS_PATH="${CLAUDE_SKILLS_PATH:-$HOME/.claude/skills/generic}"
SKILLS_DIR="$REPO_ROOT/skills"

create_symlink "$CLAUDE_SKILLS_PATH" "$SKILLS_DIR"

CLAUDE_AGENTS_PATH="${CLAUDE_AGENTS_PATH:-$HOME/.claude/agents/generic}"
AGENTS_DIR="$REPO_ROOT/agents"

create_symlink "$CLAUDE_AGENTS_PATH" "$AGENTS_DIR"

OPENCODE_COMMANDS_PATH="${OPENCODE_COMMANDS_PATH:-$HOME/.config/opencode/commands/generic}"

create_symlink "$OPENCODE_COMMANDS_PATH" "$COMMANDS_DIR"

OPENCODE_SKILLS_PATH="${OPENCODE_SKILLS_PATH:-$HOME/.config/opencode/skills/generic}"

create_symlink "$OPENCODE_SKILLS_PATH" "$SKILLS_DIR"

OPENCODE_AGENTS_PATH="${OPENCODE_AGENTS_PATH:-$HOME/.config/opencode/agents/generic}"

create_symlink "$OPENCODE_AGENTS_PATH" "$AGENTS_DIR"

echo ""
echo "✅ Configuration complete! Configured 8 symlinks for scripts, rules, commands, skills, and agents."
