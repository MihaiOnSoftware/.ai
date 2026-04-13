#!/usr/bin/env bash

set -euo pipefail

# Load required libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/symlink_helpers.sh"
source "$SCRIPT_DIR/paths.sh"

log_info "Uninstalling lib files..."

uninstall_symlink "$AI_LIB_PATH/logging.sh" "$LIB_DIR/logging.sh"
uninstall_symlink "$AI_LIB_PATH/symlink_helpers.sh" "$LIB_DIR/symlink_helpers.sh"
uninstall_symlink "$AI_LIB_PATH/paths.sh" "$LIB_DIR/paths.sh"
uninstall_symlink "$AI_LIB_PATH/agent_helpers.sh" "$LIB_DIR/agent_helpers.sh"
uninstall_symlink "$AI_LIB_PATH/install_agents.sh" "$LIB_DIR/install_agents.sh"
uninstall_symlink "$AI_LIB_PATH/uninstall_agents.sh" "$LIB_DIR/uninstall_agents.sh"
uninstall_symlink "$AI_LIB_PATH/skill_helpers.sh" "$LIB_DIR/skill_helpers.sh"
uninstall_symlink "$AI_LIB_PATH/install_skills.sh" "$LIB_DIR/install_skills.sh"
uninstall_symlink "$AI_LIB_PATH/uninstall_skills.sh" "$LIB_DIR/uninstall_skills.sh"

log_success "✅ Lib uninstallation complete!"
