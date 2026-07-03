#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logging.sh"
source "$SCRIPT_DIR/symlink_helpers.sh"
source "$SCRIPT_DIR/paths.sh"

RULES_SOURCE="${1:-$RULES_DIR}"
OUTPUT_PATH="${2:-$AGENTS_MD_PATH}"
EXTRA_SOURCE="${3:-}"

validate_source_dir "$RULES_SOURCE" "Rules directory"

log_info "Building AGENTS.md from rules in $RULES_SOURCE..."

{
    for f in "$RULES_SOURCE"/[0-9]*.md; do
        [ -f "$f" ] || continue
        cat "$f"
        printf '\n\n'
    done
    if [ -d "$EXTRA_SOURCE" ]; then
        for f in "$EXTRA_SOURCE"/[0-9]*.md; do
            [ -f "$f" ] || continue
            cat "$f"
            printf '\n\n'
        done
    fi
} > "$OUTPUT_PATH"

log_success "✅ Built AGENTS.md: $OUTPUT_PATH"
