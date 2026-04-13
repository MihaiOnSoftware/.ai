#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/symlink_helpers.sh"
source "$SCRIPT_DIR/paths.sh"

install_skills() {
    local namespace="$1"
    local source_dir="$2"

    validate_source_dir "$source_dir" "Skills directory"

    mkdir -p "$CLAUDE_SKILLS_DIR"
    for skill_dir in "$source_dir"/*/; do
        [ -d "$skill_dir" ] || continue
        [ -f "$skill_dir/SKILL.md" ] || continue
        local skill_name
        skill_name="$(basename "$skill_dir")"
        create_symlink "$CLAUDE_SKILLS_DIR/$skill_name" "$skill_dir"
    done

    create_symlink "$OPENCODE_DIR/skills/$namespace" "$source_dir"

    create_symlink "$PI_DIR/skills/$namespace" "$source_dir"
}

uninstall_skills() {
    local namespace="$1"
    local source_dir="$2"

    if [ -d "$CLAUDE_SKILLS_DIR" ]; then
        for entry in "$CLAUDE_SKILLS_DIR"/*; do
            [ -L "$entry" ] || continue
            local link_target
            link_target="$(readlink "$entry")"
            case "$link_target" in
                "$source_dir"|"$source_dir"/*)
                    rm "$entry"
                    log_info "  Removed symlink: $entry"
                    ;;
            esac
        done
    fi

    uninstall_symlink "$OPENCODE_DIR/skills/$namespace" "$source_dir"

    uninstall_symlink "$PI_DIR/skills/$namespace" "$source_dir"
}
