#!/usr/bin/env bash

set -euo pipefail

# Load logging functions
source "$(dirname "${BASH_SOURCE[0]}")/lib/logging.sh"

FORCE_MODE="false"

# Global Counters
COUNT_CREATED=0
COUNT_CORRECT=0
COUNT_WARNING=0

print_summary() {
    # If script exited with error (non-zero), we might still want to show stats
    local exit_code=$?
    
    echo ""
    echo "=============================="
    echo "      Execution Summary       "
    echo "=============================="
    echo "Created: $COUNT_CREATED"
    echo "Correct: $COUNT_CORRECT"
    echo "Warnings: $COUNT_WARNING"
    echo "=============================="
    
    # Preserve exit code if it was non-zero
    if [ $exit_code -ne 0 ]; then
        exit $exit_code
    fi
}
trap print_summary EXIT

while getopts "f" opt; do
    case $opt in
        f) FORCE_MODE="true" ;;
        *) echo "Usage: install.sh [-f]" >&2; exit 1 ;;
    esac
done


# Load path configuration
source "$(dirname "${BASH_SOURCE[0]}")/lib/paths.sh"

validate_source_directories() {
    local missing_dirs=()
    local required_dirs=(
        "$REPO_ROOT/scripts"
        "$REPO_ROOT/rules"
        "$REPO_ROOT/commands"
        "$REPO_ROOT/skills"
        "$REPO_ROOT/agents"
    )

    for dir in "${required_dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            missing_dirs+=("$dir")
        fi
    done

    if [ ${#missing_dirs[@]} -gt 0 ]; then
        log_error "✗ Error: Missing required source directories:"
        printf '  - %s\n' "${missing_dirs[@]}" >&2
        exit 2
    fi
}

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

validate_source_directories

create_symlink "$AI_SCRIPTS_PATH" "$SCRIPTS_DIR" "$FORCE_MODE"

create_symlink "$AI_RULES_PATH" "$RULES_DIR" "$FORCE_MODE"

create_symlink "$CLAUDE_COMMANDS_PATH" "$COMMANDS_DIR" "$FORCE_MODE"

create_symlink "$CLAUDE_SKILLS_PATH" "$SKILLS_DIR" "$FORCE_MODE"

create_symlink "$CLAUDE_AGENTS_PATH" "$AGENTS_DIR" "$FORCE_MODE"

create_symlink "$OPENCODE_COMMANDS_PATH" "$COMMANDS_DIR" "$FORCE_MODE"

create_symlink "$OPENCODE_SKILLS_PATH" "$SKILLS_DIR" "$FORCE_MODE"

create_symlink "$OPENCODE_AGENTS_PATH" "$AGENTS_DIR" "$FORCE_MODE"

echo ""
log_success "✅ Configuration complete! Configured 8 symlinks for scripts, rules, commands, skills, and agents."
