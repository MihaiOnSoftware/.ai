#!/usr/bin/env bash

set -euo pipefail

if [ $# -lt 2 ]; then
    echo "Usage: uninstall_skills.sh <namespace> <source_dir>" >&2
    exit 1
fi

NAMESPACE="$1"
SOURCE_DIR="$2"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/skill_helpers.sh"

log_info "Uninstalling skills..."
uninstall_skills "$NAMESPACE" "$SOURCE_DIR"
log_success "✅ Skills uninstallation complete!"
