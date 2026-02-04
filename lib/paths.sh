#!/usr/bin/env bash

# Calculate repository root relative to this file (lib/paths.sh)
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Source Directories
SCRIPTS_DIR="$REPO_ROOT/scripts"
RULES_DIR="$REPO_ROOT/rules"
COMMANDS_DIR="$REPO_ROOT/commands"
SKILLS_DIR="$REPO_ROOT/skills"
AGENTS_DIR="$REPO_ROOT/agents"

# AI Paths
AI_SCRIPTS_PATH="${AI_SCRIPTS_PATH:-$HOME/.ai/scripts/generic}"
AI_RULES_PATH="${AI_RULES_PATH:-$HOME/.ai/rules}"

# Claude Paths
CLAUDE_COMMANDS_PATH="${CLAUDE_COMMANDS_PATH:-$HOME/.claude/commands/generic}"
CLAUDE_SKILLS_PATH="${CLAUDE_SKILLS_PATH:-$HOME/.claude/skills/generic}"
CLAUDE_AGENTS_PATH="${CLAUDE_AGENTS_PATH:-$HOME/.claude/agents/generic}"

# OpenCode Paths
OPENCODE_COMMANDS_PATH="${OPENCODE_COMMANDS_PATH:-$HOME/.config/opencode/commands/generic}"
OPENCODE_SKILLS_PATH="${OPENCODE_SKILLS_PATH:-$HOME/.config/opencode/skills/generic}"
OPENCODE_AGENTS_PATH="${OPENCODE_AGENTS_PATH:-$HOME/.config/opencode/agents/generic}"
