#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logging.sh"

FORCE_MODE="${FORCE_MODE:-false}"
COUNT_CREATED="${COUNT_CREATED:-0}"
COUNT_CORRECT="${COUNT_CORRECT:-0}"
COUNT_WARNING="${COUNT_WARNING:-0}"

is_correct_symlink() {
    local target_path="$1"
    local source_dir="$2"

    if [ -L "$target_path" ]; then
        local existing_target
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

    mkdir -p "$(dirname "$target_path")"

    if is_correct_symlink "$target_path" "$source_dir"; then
        log_success "✓ Symlink already exists: $target_path"
        COUNT_CORRECT=$((COUNT_CORRECT + 1))
        return 0
    fi

    if [ -e "$target_path" ] && [ ! -L "$target_path" ]; then
        log_error "✗ Error: $target_path exists and is not a symlink"
        exit 1
    fi

    if [ -L "$target_path" ]; then
        if [ "${FORCE_MODE:-false}" = "true" ]; then
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

uninstall_symlink() {
    local target_path="$1"
    local source_dir="$2"

    if [ -e "$target_path" ] || [ -L "$target_path" ]; then
        if [ -L "$target_path" ]; then
            local existing_target
            existing_target="$(readlink "$target_path")"
            if [ "$existing_target" = "$source_dir" ]; then
                rm "$target_path"
                log_success "Removed symlink: $target_path"
            else
                log_warning "Skipping path: Not a symlink to this repo"
                echo "  Path:   $target_path"
                echo "  Points: $existing_target"
                echo "  Expect: $source_dir"
            fi
        else
            log_warning "Skipping path: Not a symlink"
            echo "  Path: $target_path"
        fi
    else
        log_info "Skipping path: Does not exist"
        echo "  Path: $target_path"
    fi
}

validate_source_dir() {
    local dir_path="$1"
    local label="$2"

    if [ ! -d "$dir_path" ]; then
        log_error "✗ Error: $label not found: $dir_path"
        exit 2
    fi
}
