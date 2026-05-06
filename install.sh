#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load logging functions
source "$SCRIPT_DIR/lib/logging.sh"

export FORCE_MODE=false

# Parse arguments
while getopts "f" opt; do
    case $opt in
        f) export FORCE_MODE=true ;;
        *) echo "Usage: install.sh [-f]" >&2; exit 1 ;;
    esac
done

log_info "Starting installation..."
echo ""

# Install lib first (must use relative path — creates the ~/.ai/lib/ symlinks)
"$SCRIPT_DIR/lib/install_lib.sh"

# These use the shared helpers via ~/.ai/lib/
"$HOME/.ai/lib/install_skills.sh" "$SCRIPT_DIR/skills"
"$HOME/.ai/lib/install_agents.sh" "$SCRIPT_DIR/agents"

# These aren't converted yet, stay as relative paths
"$SCRIPT_DIR/lib/install_scripts.sh"
"$SCRIPT_DIR/lib/install_rules.sh"

echo ""
log_success "✅ Configuration complete! Configured symlinks for lib, scripts, rules, skills, and agents (across Claude Code, OpenCode, and pi)."
