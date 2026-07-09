#!/usr/bin/env bash

set -euo pipefail

if [ $# -lt 1 ]; then
    echo "Usage: install_pi_settings.sh <source_file>" >&2
    exit 1
fi

SOURCE_FILE="$1"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/pi_settings_helpers.sh"

log_info "Installing pi settings..."
install_pi_settings "$SOURCE_FILE"
log_success "✅ Pi settings installation complete! (Merged keys: ${PI_SETTINGS_APPLIED:-none})"
