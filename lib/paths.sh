#!/usr/bin/env bash

# Calculate repository root relative to this file (lib/paths.sh)
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Source Directories
LIB_DIR="$REPO_ROOT/lib"
SCRIPTS_DIR="$REPO_ROOT/scripts"
RULES_DIR="$REPO_ROOT/rules"

# AI Paths
AI_LIB_PATH="${AI_LIB_PATH:-$HOME/.ai/lib}"
AI_SCRIPTS_PATH="${AI_SCRIPTS_PATH:-$HOME/.ai/scripts/generic}"
AI_RULES_PATH="${AI_RULES_PATH:-$HOME/.ai/rules}"

# Claude Paths (honors Claude Code's CLAUDE_CONFIG_DIR)
CLAUDE_CONFIG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
# Skills are symlinked per-skill into flat directories: <skills-dir>/<skill-name>/
CLAUDE_SKILLS_DIR="${CLAUDE_SKILLS_DIR:-$CLAUDE_CONFIG_DIR/skills}"
CLAUDE_AGENTS_DIR="${CLAUDE_AGENTS_DIR:-$CLAUDE_CONFIG_DIR/agents}"

# OpenCode Paths (honors OpenCode's OPENCODE_CONFIG_DIR)
OPENCODE_CONFIG_DIR="${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}"
OPENCODE_SKILLS_DIR="${OPENCODE_SKILLS_DIR:-$OPENCODE_CONFIG_DIR/skills}"
OPENCODE_AGENTS_DIR="${OPENCODE_AGENTS_DIR:-$OPENCODE_CONFIG_DIR/agents}"


# Pi Paths (honors pi's PI_CODING_AGENT_DIR)
PI_CODING_AGENT_DIR="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"
PI_SKILLS_DIR="${PI_SKILLS_DIR:-$PI_CODING_AGENT_DIR/skills}"
PI_AGENTS_DIR="${PI_AGENTS_DIR:-$PI_CODING_AGENT_DIR/agents}"

# MCP Paths
# MCP servers are installed into Claude (user scope, ~/.claude.json) via the
# claude CLI; pi reads them through pi-mcp-adapter's claude-code import, which
# we register in pi's agent MCP config below.
PI_MCP_CONFIG_PATH="${PI_MCP_CONFIG_PATH:-$PI_CODING_AGENT_DIR/mcp.json}"
# Claude's user-scope config (where `claude mcp ... -s user` stores servers);
# read on uninstall to decide whether pi still needs the claude-code import.
CLAUDE_USER_CONFIG="${CLAUDE_USER_CONFIG:-$HOME/.claude.json}"


