#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load logging functions
source "$SCRIPT_DIR/lib/logging.sh"

echo "=============================="
echo "      Uninstalling...         "
echo "=============================="
echo ""

# These use shared helpers via ~/.ai/lib/
"$HOME/.ai/lib/uninstall_skills.sh" "$SCRIPT_DIR/skills"
echo ""

"$HOME/.ai/lib/uninstall_agents.sh" "$SCRIPT_DIR/agents"
echo ""

# These aren't converted yet, stay as relative paths
"$SCRIPT_DIR/lib/uninstall_scripts.sh"
echo ""

"$SCRIPT_DIR/lib/uninstall_rules.sh"
echo ""

# Uninstall lib last (must use relative path — removes the ~/.ai/lib/ symlinks)
"$SCRIPT_DIR/lib/uninstall_lib.sh"

echo ""
log_success "✅ Uninstall complete!"
