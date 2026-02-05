#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load logging functions
source "$SCRIPT_DIR/lib/logging.sh"

FORCE_FLAG=""

# Parse arguments
while getopts "f" opt; do
    case $opt in
        f) FORCE_FLAG="-f" ;;
        *) echo "Usage: install.sh [-f]" >&2; exit 1 ;;
    esac
done

log_info "Starting installation..."
echo ""

# Run modular install scripts
"$SCRIPT_DIR/lib/install_scripts.sh" $FORCE_FLAG
echo ""

"$SCRIPT_DIR/lib/install_rules.sh" $FORCE_FLAG
echo ""

"$SCRIPT_DIR/lib/install_commands.sh" $FORCE_FLAG
echo ""

"$SCRIPT_DIR/lib/install_skills.sh" $FORCE_FLAG
echo ""

"$SCRIPT_DIR/lib/install_agents.sh" $FORCE_FLAG

echo ""
log_success "✅ Configuration complete! Configured 8 symlinks for scripts, rules, commands, skills, and agents."
