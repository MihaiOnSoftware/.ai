#!/usr/bin/env bash

set -euo pipefail

# Load required libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/agent_helpers.sh"

log_info "Uninstalling agents..."
uninstall_agents "$AGENTS_DIR"
log_success "✅ Agents uninstallation complete!"
