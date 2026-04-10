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

# Run modular install scripts
"$SCRIPT_DIR/lib/install_scripts.sh"
"$SCRIPT_DIR/lib/install_rules.sh"

# Replaced in favour of skills
# "$SCRIPT_DIR/lib/install_commands.sh"

"$SCRIPT_DIR/lib/install_skills.sh"
"$SCRIPT_DIR/lib/install_agents.sh"
"$SCRIPT_DIR/lib/install_pi.sh"

echo ""
log_success "✅ Configuration complete! Configured symlinks for scripts, rules, commands, skills, agents, and pi."
