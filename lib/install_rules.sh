#!/usr/bin/env bash

set -euo pipefail

# Load required libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logging.sh"
source "$SCRIPT_DIR/paths.sh"

FORCE_MODE="${FORCE_MODE:-false}"
COUNT_CREATED="${COUNT_CREATED:-0}"
COUNT_CORRECT="${COUNT_CORRECT:-0}"
COUNT_WARNING="${COUNT_WARNING:-0}"

# Parse arguments
while getopts "f" opt; do
    case $opt in
        f) FORCE_MODE="true" ;;
        *) echo "Usage: install_rules.sh [-f]" >&2; exit 1 ;;
    esac
done

is_correct_symlink() {
    local target_path="$1"
    local source_dir="$2"

    if [ -L "$target_path" ]; then
        existing_target="$(readlink "$target_path")"
        if [ "$existing_target" = "$source_dir" ]; then
            return 0
        fi
    fi
    return 1
}

create_symlink() {
    local target_path="$1"
    local source_dir="$2"
    local force_mode="$3"

    mkdir -p "$(dirname "$target_path")"

    if is_correct_symlink "$target_path" "$source_dir"; then
        log_success "✓ Symlink already exists: $target_path"
        COUNT_CORRECT=$((COUNT_CORRECT + 1))
        return 0
    fi

    # Safety check: never overwrite regular files/directories
    if [ -e "$target_path" ] && [ ! -L "$target_path" ]; then
        log_error "✗ Error: $target_path exists and is not a symlink"
        exit 1
    fi

    if [ -L "$target_path" ]; then
        if [ "$force_mode" = "true" ]; then
            log_info "⚠ Fixing wrong symlink: $target_path"
            rm "$target_path"
        else
            log_warning "⚠ Warning: $target_path is a symlink to wrong location"
            log_warning "  Use -f flag to fix wrong symlinks"
            COUNT_WARNING=$((COUNT_WARNING + 1))
            exit 1
        fi
    fi

    ln -s "$source_dir" "$target_path"
    log_info "➕ Created symlink: $target_path -> $source_dir"
    COUNT_CREATED=$((COUNT_CREATED + 1))
}

# Validate source directory
if [ ! -d "$RULES_DIR" ]; then
    log_error "✗ Error: Rules directory not found: $RULES_DIR"
    exit 2
fi

log_info "Installing rules..."

create_symlink "$AI_RULES_PATH" "$RULES_DIR" "$FORCE_MODE"

log_success "✅ Rules installation complete! (Created: $COUNT_CREATED, Correct: $COUNT_CORRECT, Warnings: $COUNT_WARNING)"
