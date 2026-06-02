#!/usr/bin/env bash

set -euo pipefail

if [ $# -lt 1 ]; then
    echo "Usage: install_mcp.sh <source_file>" >&2
    exit 1
fi

SOURCE_FILE="$1"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/mcp_helpers.sh"

log_info "Installing MCP servers..."
install_mcp "$SOURCE_FILE"
log_success "✅ MCP servers installation complete! (Added: $MCP_COUNT_ADDED, Updated: $MCP_COUNT_UPDATED, Present: $MCP_COUNT_PRESENT)"
