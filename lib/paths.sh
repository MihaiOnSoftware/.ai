#!/usr/bin/env bash

# Calculate repository root relative to this file (lib/paths.sh)
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Source Directories
LIB_DIR="$REPO_ROOT/lib"
SCRIPTS_DIR="$REPO_ROOT/scripts"
RULES_DIR="$REPO_ROOT/rules"
COMMANDS_DIR="$REPO_ROOT/commands"

# AI Paths
AI_LIB_PATH="${AI_LIB_PATH:-$HOME/.ai/lib}"
AI_SCRIPTS_PATH="${AI_SCRIPTS_PATH:-$HOME/.ai/scripts/generic}"
AI_RULES_PATH="${AI_RULES_PATH:-$HOME/.ai/rules}"

# Claude Paths (honors Claude Code's CLAUDE_CONFIG_DIR)
CLAUDE_CONFIG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
CLAUDE_COMMANDS_PATH="${CLAUDE_COMMANDS_PATH:-$CLAUDE_CONFIG_DIR/commands/generic}"
# Skills are symlinked per-skill into flat directories: <skills-dir>/<skill-name>/
CLAUDE_SKILLS_DIR="${CLAUDE_SKILLS_DIR:-$CLAUDE_CONFIG_DIR/skills}"
CLAUDE_AGENTS_DIR="${CLAUDE_AGENTS_DIR:-$CLAUDE_CONFIG_DIR/agents}"

# OpenCode Paths (honors OpenCode's OPENCODE_CONFIG_DIR)
OPENCODE_CONFIG_DIR="${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}"
OPENCODE_COMMANDS_PATH="${OPENCODE_COMMANDS_PATH:-$OPENCODE_CONFIG_DIR/commands/generic}"
OPENCODE_SKILLS_DIR="${OPENCODE_SKILLS_DIR:-$OPENCODE_CONFIG_DIR/skills}"
OPENCODE_AGENTS_DIR="${OPENCODE_AGENTS_DIR:-$OPENCODE_CONFIG_DIR/agents}"

# Pi Paths (honors pi's PI_CODING_AGENT_DIR)
PI_CODING_AGENT_DIR="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"
PI_SKILLS_DIR="${PI_SKILLS_DIR:-$PI_CODING_AGENT_DIR/skills}"
PI_AGENTS_DIR="${PI_AGENTS_DIR:-$PI_CODING_AGENT_DIR/agents}"


