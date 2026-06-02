#!/usr/bin/env bash

set -euo pipefail

# Load required libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/symlink_helpers.sh"
source "$SCRIPT_DIR/paths.sh"

validate_source_dir "$LIB_DIR" "Lib directory"

log_info "Installing lib files..."

# One-time migration: remove stale regular file from before symlink management
if [ -e "$AI_LIB_PATH/paths.sh" ] && [ ! -L "$AI_LIB_PATH/paths.sh" ]; then
    rm "$AI_LIB_PATH/paths.sh"
    log_info "Removed stale $AI_LIB_PATH/paths.sh (replaced by symlink)"
fi

create_symlink "$AI_LIB_PATH/logging.sh" "$LIB_DIR/logging.sh"
create_symlink "$AI_LIB_PATH/symlink_helpers.sh" "$LIB_DIR/symlink_helpers.sh"
create_symlink "$AI_LIB_PATH/paths.sh" "$LIB_DIR/paths.sh"
create_symlink "$AI_LIB_PATH/agent_helpers.sh" "$LIB_DIR/agent_helpers.sh"
create_symlink "$AI_LIB_PATH/install_agents.sh" "$LIB_DIR/install_agents.sh"
create_symlink "$AI_LIB_PATH/uninstall_agents.sh" "$LIB_DIR/uninstall_agents.sh"
create_symlink "$AI_LIB_PATH/skill_helpers.sh" "$LIB_DIR/skill_helpers.sh"
create_symlink "$AI_LIB_PATH/install_skills.sh" "$LIB_DIR/install_skills.sh"
create_symlink "$AI_LIB_PATH/uninstall_skills.sh" "$LIB_DIR/uninstall_skills.sh"
create_symlink "$AI_LIB_PATH/pi_package_helpers.sh" "$LIB_DIR/pi_package_helpers.sh"
create_symlink "$AI_LIB_PATH/install_pi_packages.sh" "$LIB_DIR/install_pi_packages.sh"
create_symlink "$AI_LIB_PATH/uninstall_pi_packages.sh" "$LIB_DIR/uninstall_pi_packages.sh"
create_symlink "$AI_LIB_PATH/mcp_helpers.sh" "$LIB_DIR/mcp_helpers.sh"
create_symlink "$AI_LIB_PATH/install_mcp.sh" "$LIB_DIR/install_mcp.sh"
create_symlink "$AI_LIB_PATH/uninstall_mcp.sh" "$LIB_DIR/uninstall_mcp.sh"

log_success "✅ Lib installation complete! (Created: $COUNT_CREATED, Correct: $COUNT_CORRECT, Warnings: $COUNT_WARNING)"
