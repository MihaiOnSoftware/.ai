#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load logging functions
source "$SCRIPT_DIR/lib/logging.sh"

echo "=============================="
echo "      Uninstalling...         "
echo "=============================="
echo ""

# Run modular uninstall scripts
"$SCRIPT_DIR/lib/uninstall_scripts.sh"
echo ""

"$SCRIPT_DIR/lib/uninstall_rules.sh"
echo ""

"$SCRIPT_DIR/lib/uninstall_commands.sh"
echo ""

"$SCRIPT_DIR/lib/uninstall_skills.sh"
echo ""

"$SCRIPT_DIR/lib/uninstall_agents.sh"

echo ""
log_success "✅ Uninstall complete!"
