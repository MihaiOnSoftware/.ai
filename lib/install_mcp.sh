#!/usr/bin/env bash

set -euo pipefail

if [ $# -lt 1 ]; then
    echo "Usage: install_mcp.sh <source_file>" >&2
    exit 1
fi

SOURCE_FILE="$1"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/mcp_helpers.sh"

log_info "Installing MCP servers (generating per-host configs)..."
install_mcp "$SOURCE_FILE"
log_success "✅ MCP servers installation complete! (pi: ${MCP_PI_APPLIED:-none}; OpenCode: ${MCP_OPENCODE_APPLIED:-none})"
