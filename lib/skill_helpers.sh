#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/symlink_helpers.sh"
source "$SCRIPT_DIR/paths.sh"

install_skills() {
    local source_dir="$1"

    validate_source_dir "$source_dir" "Skills directory"

    for target_dir in "$CLAUDE_SKILLS_DIR" "$OPENCODE_SKILLS_DIR" "$PI_SKILLS_DIR"; do
        mkdir -p "$target_dir"
        for skill_dir in "$source_dir"/*/; do
            [ -d "$skill_dir" ] || continue
            [ -f "$skill_dir/SKILL.md" ] || continue
            local skill_name
            skill_name="$(basename "$skill_dir")"
            create_symlink "$target_dir/$skill_name" "$skill_dir"
        done
    done
}

uninstall_skills() {
    local source_dir="$1"

    # Clean up old namespace directory symlinks (pre-refactor format)
    for old_dir_symlink in "$CLAUDE_SKILLS_DIR/generic" "$OPENCODE_SKILLS_DIR/generic" "$PI_SKILLS_DIR/generic"; do
        if [ -L "$old_dir_symlink" ]; then
            rm "$old_dir_symlink"
            log_info "  Removed old directory symlink: $old_dir_symlink"
        fi
    done

    for target_dir in "$CLAUDE_SKILLS_DIR" "$OPENCODE_SKILLS_DIR" "$PI_SKILLS_DIR"; do
        [ -d "$target_dir" ] || continue
        for entry in "$target_dir"/*; do
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
    done
}
