#!/usr/bin/env bash

set -euo pipefail

if [ $# -lt 1 ]; then
    echo "Usage: install_pi_packages.sh <source_file>" >&2
    exit 1
fi

SOURCE_FILE="$1"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/pi_package_helpers.sh"

log_info "Installing pi packages..."
install_pi_packages "$SOURCE_FILE"
log_success "✅ Pi packages installation complete! (Installed: $COUNT_CREATED, Present: $COUNT_CORRECT)"
