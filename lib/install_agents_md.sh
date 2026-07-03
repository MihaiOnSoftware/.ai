#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/symlink_helpers.sh"
source "$SCRIPT_DIR/paths.sh"

validate_source_dir "$RULES_DIR" "Rules directory"

log_info "Installing AGENTS.md..."

"$SCRIPT_DIR/build_agents_md.sh" "$RULES_DIR" "$AGENTS_MD_PATH" "$CLAUDE_RULES_DIR"
"$SCRIPT_DIR/build_agents_md.sh" "$RULES_DIR" "$PI_AGENTS_BUILT_PATH" "$PI_RULES_DIR"

validate_source_file "$AGENTS_MD_PATH" "Generated AGENTS.md"
validate_source_file "$PI_AGENTS_BUILT_PATH" "Generated PI_AGENTS.md"

create_symlink "$CLAUDE_AGENTS_MD_PATH" "$AGENTS_MD_PATH"
create_symlink "$PI_AGENTS_MD_PATH" "$PI_AGENTS_BUILT_PATH"

log_success "✅ AGENTS.md installation complete! (Created: $COUNT_CREATED, Correct: $COUNT_CORRECT, Warnings: $COUNT_WARNING)"
