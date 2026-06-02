#!/usr/bin/env bash

set -euo pipefail

if [ $# -lt 1 ]; then
    echo "Usage: uninstall_mcp.sh <source_file>" >&2
    exit 1
fi

SOURCE_FILE="$1"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/mcp_helpers.sh"

log_info "Uninstalling MCP servers..."
uninstall_mcp "$SOURCE_FILE"
log_success "✅ MCP servers uninstallation complete! (Removed: $MCP_COUNT_REMOVED, Skipped: $MCP_COUNT_SKIPPED)"
