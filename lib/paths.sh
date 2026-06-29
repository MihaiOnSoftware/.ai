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

# pi-managed npm package tree (where `pi install npm:...` materializes extensions)
PI_NPM_MODULES_DIR="${PI_NPM_MODULES_DIR:-$PI_CODING_AGENT_DIR/npm/node_modules}"
# TEMPORARY: symlink target for the pi-subagents#334 async-runner workaround.
# Remove this var together with the workaround once upstream ships a fix:
# https://github.com/nicobailon/pi-subagents/issues/334
PI_SUBAGENTS_PCA_LINK="${PI_SUBAGENTS_PCA_LINK:-$PI_NPM_MODULES_DIR/@earendil-works/pi-coding-agent}"

# Generated context file (built from rules on install, gitignored)
AGENTS_MD_PATH="$REPO_ROOT/AGENTS.md"
PI_AGENTS_MD_PATH="$PI_CODING_AGENT_DIR/AGENTS.md"
CLAUDE_AGENTS_MD_PATH="$CLAUDE_CONFIG_DIR/CLAUDE.md"

# MCP Paths
# MCP servers are declared in a canonical mcpServers JSON file (pi-mcp-adapter
# schema, no secrets) and *generated* into each host's native MCP config by
# lib/mcp_helpers.sh (pi + OpenCode). Claude is intentionally not a target for
# now; the per-host emitter layout leaves a seam to add it back later.
PI_MCP_CONFIG_PATH="${PI_MCP_CONFIG_PATH:-$PI_CODING_AGENT_DIR/mcp.json}"
OPENCODE_MCP_CONFIG_PATH="${OPENCODE_MCP_CONFIG_PATH:-$OPENCODE_CONFIG_DIR/opencode.json}"


