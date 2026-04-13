#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/symlink_helpers.sh"
source "$SCRIPT_DIR/paths.sh"

install_agents() {
    local source_dir="$1"

    validate_source_dir "$source_dir" "Agents directory"

    for target_dir in "$CLAUDE_AGENTS_DIR" "$OPENCODE_AGENTS_DIR" "$PI_AGENTS_DIR"; do
        mkdir -p "$target_dir"
        for agent_file in "$source_dir"/*.md; do
            [ -f "$agent_file" ] || continue
            create_symlink "$target_dir/$(basename "$agent_file")" "$agent_file"
        done
    done
}

uninstall_agents() {
    local source_dir="$1"

    for target_dir in "$CLAUDE_AGENTS_DIR" "$OPENCODE_AGENTS_DIR" "$PI_AGENTS_DIR"; do
        [ -d "$target_dir" ] || continue
        for entry in "$target_dir"/*; do
            [ -L "$entry" ] || continue
            local link_target
            link_target="$(readlink "$entry")"
            case "$link_target" in
                "$source_dir"/*)
                    rm "$entry"
                    log_info "  Removed symlink: $entry"
                    ;;
            esac
        done
    done
}
