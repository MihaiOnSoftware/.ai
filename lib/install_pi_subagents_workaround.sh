#!/usr/bin/env bash

set -euo pipefail

# TEMPORARY WORKAROUND for pi-subagents#334 — full rationale lives in
# pi_package_helpers.sh. The detached async subagent runner can't resolve
# @earendil-works/pi-coding-agent and crashes at import, so async/parallel
# subagents fail silently. This symlinks the host pi's copy into pi's npm tree.
# Remove this script (and its call in install.sh) once upstream ships a fix:
# https://github.com/nicobailon/pi-subagents/issues/334

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/pi_package_helpers.sh"
source "$SCRIPT_DIR/paths.sh"

log_info "Applying pi-subagents async-runner workaround (pi-subagents#334)..."
install_pi_subagents_workaround "$PI_SUBAGENTS_PCA_LINK"
log_success "✅ pi-subagents#334 workaround applied (Created: $COUNT_CREATED, Correct: $COUNT_CORRECT, Warnings: $COUNT_WARNING)"
