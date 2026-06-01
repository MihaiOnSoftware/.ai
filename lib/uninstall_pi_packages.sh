#!/usr/bin/env bash

set -euo pipefail

if [ $# -lt 1 ]; then
    echo "Usage: uninstall_pi_packages.sh <source_file>" >&2
    exit 1
fi

SOURCE_FILE="$1"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/pi_package_helpers.sh"

log_info "Uninstalling pi packages..."
uninstall_pi_packages "$SOURCE_FILE"
log_success "✅ Pi packages uninstallation complete!"
