#!/usr/bin/env bash

set -euo pipefail

if [ $# -lt 1 ]; then
    echo "Usage: install_agents.sh <source_dir>" >&2
    exit 1
fi

SOURCE_DIR="$1"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/agent_helpers.sh"

log_info "Installing agents..."
install_agents "$SOURCE_DIR"
log_success "✅ Agents installation complete! (Created: $COUNT_CREATED, Correct: $COUNT_CORRECT, Warnings: $COUNT_WARNING)"
