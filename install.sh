#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

create_symlink() {
    local target_path="$1"
    local source_dir="$2"

    mkdir -p "$(dirname "$target_path")"

    if [ -e "$target_path" ] && [ ! -L "$target_path" ]; then
        echo "Error: $target_path exists but is not a symlink" >&2
        exit 1
    fi

    if [ -L "$target_path" ]; then
        existing_target="$(readlink "$target_path")"
        if [ "$existing_target" = "$source_dir" ]; then
            echo "Symlink already exists and points to correct location: $target_path"
            return 0
        fi
        rm "$target_path"
    fi

    ln -s "$source_dir" "$target_path"
    echo "Created symlink: $target_path -> $source_dir"
}

AI_SCRIPTS_PATH="${AI_SCRIPTS_PATH:-$HOME/.ai/scripts/generic}"
GENERIC_SCRIPTS_DIR="$REPO_ROOT/scripts/generic"

mkdir -p "$GENERIC_SCRIPTS_DIR"
touch "$GENERIC_SCRIPTS_DIR/.keep"

create_symlink "$AI_SCRIPTS_PATH" "$GENERIC_SCRIPTS_DIR"

AI_RULES_PATH="${AI_RULES_PATH:-$HOME/.ai/rules}"
RULES_DIR="$REPO_ROOT/rules"

create_symlink "$AI_RULES_PATH" "$RULES_DIR"

CLAUDE_COMMANDS_PATH="${CLAUDE_COMMANDS_PATH:-$HOME/.claude/commands/generic}"
COMMANDS_DIR="$REPO_ROOT/commands/generic"

mkdir -p "$COMMANDS_DIR"
touch "$COMMANDS_DIR/.keep"

create_symlink "$CLAUDE_COMMANDS_PATH" "$COMMANDS_DIR"

CLAUDE_SKILLS_PATH="${CLAUDE_SKILLS_PATH:-$HOME/.claude/skills/generic}"
SKILLS_DIR="$REPO_ROOT/skills/generic"

mkdir -p "$SKILLS_DIR"
touch "$SKILLS_DIR/.keep"

create_symlink "$CLAUDE_SKILLS_PATH" "$SKILLS_DIR"

CLAUDE_AGENTS_PATH="${CLAUDE_AGENTS_PATH:-$HOME/.claude/agents/generic}"
AGENTS_DIR="$REPO_ROOT/agents/generic"

mkdir -p "$AGENTS_DIR"
touch "$AGENTS_DIR/.keep"

create_symlink "$CLAUDE_AGENTS_PATH" "$AGENTS_DIR"

OPENCODE_COMMANDS_PATH="${OPENCODE_COMMANDS_PATH:-$HOME/.config/opencode/commands/generic}"

create_symlink "$OPENCODE_COMMANDS_PATH" "$COMMANDS_DIR"

OPENCODE_SKILLS_PATH="${OPENCODE_SKILLS_PATH:-$HOME/.config/opencode/skills/generic}"

create_symlink "$OPENCODE_SKILLS_PATH" "$SKILLS_DIR"

OPENCODE_AGENTS_PATH="${OPENCODE_AGENTS_PATH:-$HOME/.config/opencode/agents/generic}"

create_symlink "$OPENCODE_AGENTS_PATH" "$AGENTS_DIR"
