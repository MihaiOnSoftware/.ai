#!/usr/bin/env bash

set -euo pipefail

# TEMPORARY WORKAROUND removal for pi-subagents#334 — see pi_package_helpers.sh.
# https://github.com/nicobailon/pi-subagents/issues/334

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/pi_package_helpers.sh"
source "$SCRIPT_DIR/paths.sh"

log_info "Removing pi-subagents async-runner workaround (pi-subagents#334)..."
uninstall_pi_subagents_workaround "$PI_SUBAGENTS_PCA_LINK"
log_success "✅ pi-subagents#334 workaround removal complete!"
