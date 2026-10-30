#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILL_NAME="writing-like-mihai"
SKILL_DIR="$REPO_ROOT/skills/$SKILL_NAME"
SKILL_MD="$SKILL_DIR/SKILL.md"
REFERENCE_FILES=(references/examples.md references/surfaces.md)

PASS=0
FAIL=0

pass() { echo "✓ $1"; PASS=$((PASS + 1)); }
fail() { echo "✗ $1"; FAIL=$((FAIL + 1)); }

assert() {
    local desc="$1"; shift
    if "$@" >/dev/null 2>&1; then pass "$desc"; else fail "$desc"; fi
}

# ── Frontmatter helpers ───────────────────────────────────────────────────────

frontmatter_field() {
    ruby -ryaml -e '
        text = File.read(ARGV[0])
        match = text.match(/\A---\n(.*?)\n---\n/m) or exit 1
        data = YAML.safe_load(match[1]) or exit 1
        value = data[ARGV[1]]
        exit 1 if value.nil?
        print value
    ' "${2:-$SKILL_MD}" "$1"
}

ruby_is_available() { command -v ruby >/dev/null; }

name_is_directory_name() {
    local name
    name="$(frontmatter_field name)" || return 1
    [ "$name" = "$SKILL_NAME" ]
}

description_is_non_empty() {
    local description
    description="$(frontmatter_field description)" || return 1
    [ -n "$description" ]
}

description_is_under_limit() {
    local description
    description="$(frontmatter_field description)" || return 1
    [ "${#description}" -lt 1024 ]
}

description_is_third_person() {
    local description
    description="$(frontmatter_field description)" || return 1
    ! grep -Eiq "\b(I can|You can use)\b" <<< "$description"
}

# ── Em-dash helpers ───────────────────────────────────────────────────────────

SANDBOX=""
trap '[ -z "$SANDBOX" ] || rm -rf "$SANDBOX"' EXIT

markdown_files_exist() { [ -n "$(find "$1" -name '*.md' -type f 2>/dev/null)" ]; }

em_dash_in_markdown() {
    LC_ALL=C grep -rqF --include='*.md' "$(printf '\xe2\x80\x94')" "$1"
}

markdown_has_no_em_dash() {
    markdown_files_exist "$1" && ! em_dash_in_markdown "$1"
}

planted_em_dash_is_detected() {
    SANDBOX="$(mktemp -d)"
    mkdir -p "$SANDBOX/skill/references"
    cp -R "$SKILL_DIR/." "$SANDBOX/skill/" 2>/dev/null || true
    printf 'planted \xe2\x80\x94 here\n' > "$SANDBOX/skill/references/planted.md"
    em_dash_in_markdown "$SANDBOX/skill"
}

# ── Link and inventory helpers ────────────────────────────────────────────────

skill_links_resolve() {
    local dir="$1" links link
    links="$(grep -ohE 'references/[^) ]+\.md' "$dir/SKILL.md" 2>/dev/null)" || return 1
    while IFS= read -r link; do
        [ -f "$dir/$link" ] || return 1
    done <<< "$links"
}

references_link_onward() {
    grep -rqE '\]\([^)#]*(references/|\.md)' "$1/references"
}

references_have_no_onward_links() {
    markdown_files_exist "$1/references" && ! references_link_onward "$1"
}

skill_has_exactly_three_files() {
    local expected inventory
    expected="$(printf './%s\n' SKILL.md "${REFERENCE_FILES[@]}" | LC_ALL=C sort)"
    inventory="$(cd "$1" && find . ! -type d | LC_ALL=C sort)" || return 1
    [ "$inventory" = "$expected" ]
}

planted_dangling_link_is_detected() {
    SANDBOX="${SANDBOX:-$(mktemp -d)}"
    mkdir -p "$SANDBOX/dangling/references"
    printf 'Load [surfaces](references/ok.md) first.\n' > "$SANDBOX/dangling/SKILL.md"
    printf 'body\n' > "$SANDBOX/dangling/references/ok.md"
    skill_links_resolve "$SANDBOX/dangling" || return 1
    rm "$SANDBOX/dangling/references/ok.md"
    ! skill_links_resolve "$SANDBOX/dangling"
}

planted_onward_link_is_detected() {
    SANDBOX="${SANDBOX:-$(mktemp -d)}"
    mkdir -p "$SANDBOX/onward/references"
    printf 'body\n' > "$SANDBOX/onward/references/a.md"
    references_have_no_onward_links "$SANDBOX/onward" || return 1
    printf 'See [b](b.md)\n' >> "$SANDBOX/onward/references/a.md"
    ! references_have_no_onward_links "$SANDBOX/onward"
}

# ── Contents, mention, and size helpers ───────────────────────────────────────

line_count() { grep -c '' "$1"; }

strip_final_newline() {
    local body
    body="$(cat "$1")"
    printf '%s' "$body" > "$1"
}

has_table_of_contents() {
    awk '
        left > 0 { left--; if ($0 ~ /^([-*]|[0-9]+\.) /) found = 1 }
        NR <= 30 && tolower($0) ~ /^#+ +(table of )?contents *$/ { left = 15 }
        END { exit !found }
    ' "$1"
}

references_without_contents() {
    local file
    while IFS= read -r file; do
        [ "$(line_count "$file")" -le 100 ] || has_table_of_contents "$file" || echo "$file"
    done < <(find "$1/references" -type f)
}

long_references_have_contents() {
    markdown_files_exist "$1/references" && [ -z "$(references_without_contents "$1")" ]
}

reference_is_mentioned_once_with_reason() {
    local md="$1/SKILL.md" ref="$2" pattern
    [ "$(grep -oF -- "$ref" "$md" 2>/dev/null | grep -c '')" -eq 1 ] || return 1
    pattern="\bload\b.*(^|[ \`(])${ref//./\\.}([^[:alnum:]_./-]|\$).*\b(when|if|for|to)\b( +[[:alnum:]][^ ]*){3,}"
    grep -F -- "$ref" "$md" | grep -Eiq "$pattern"
}

skill_mentions_each_reference_with_reason() {
    local ref
    for ref in "${REFERENCE_FILES[@]}"; do
        reference_is_mentioned_once_with_reason "$1" "$ref" || return 1
    done
}

skill_is_at_most_120_lines() {
    [ -f "$1/SKILL.md" ] && [ "$(line_count "$1/SKILL.md")" -le 120 ]
}

planted_reference_check() {
    SANDBOX="${SANDBOX:-$(mktemp -d)}"
    rm -rf "$SANDBOX/toc"
    mkdir -p "$SANDBOX/toc/references"
    seq 1 "$1" | awk -v at="$2" -v block="$3" '{ print (NR == at ? block : $0) }' > "$SANDBOX/toc/references/a.md"
    [ -z "${4:-}" ] || strip_final_newline "$SANDBOX/toc/references/a.md"
    long_references_have_contents "$SANDBOX/toc"
}

planted_reference_is_accepted() { planted_reference_check "$@"; }
planted_reference_is_rejected() { ! planted_reference_check "$@"; }

planted_mentions_check() {
    SANDBOX="${SANDBOX:-$(mktemp -d)}"
    mkdir -p "$SANDBOX/mentions"
    printf '%s\n' "$@" > "$SANDBOX/mentions/SKILL.md"
    skill_mentions_each_reference_with_reason "$SANDBOX/mentions"
}

planted_mentions_are_accepted() { planted_mentions_check "$@"; }
planted_mentions_are_rejected() { ! planted_mentions_check "$@"; }

planted_skill_check() {
    SANDBOX="${SANDBOX:-$(mktemp -d)}"
    mkdir -p "$SANDBOX/size"
    seq 1 "$1" > "$SANDBOX/size/SKILL.md"
    [ -z "${2:-}" ] || strip_final_newline "$SANDBOX/size/SKILL.md"
    skill_is_at_most_120_lines "$SANDBOX/size"
}

planted_skill_is_accepted() { planted_skill_check "$@"; }
planted_skill_is_rejected() { ! planted_skill_check "$@"; }

# ── Rule pointer helpers ──────────────────────────────────────────────────────

RULE_GLOB='rules/*writing_style.md'
RULE_GLOB_MENTION="(^|[^[:alnum:]_.*-])rules/\\*writing_style\\.md(\\.?\$|\\.[^[:alnum:]_]|[^[:alnum:]_.*/-])"
NUMBERED_RULE_NAME='[0-9]_writing_style'

rule_glob_matches_one_regular_file() {
    local matches
    matches="$(cd "$1" 2>/dev/null && compgen -G "$RULE_GLOB" || true)"
    [ -n "$matches" ] || return 1
    [ "$(grep -c '' <<< "$matches")" -eq 1 ] || return 1
    [ -f "$1/$matches" ] && [ ! -L "$1/$matches" ]
}

skill_refers_to_rule_by_glob() {
    grep -Eq "$RULE_GLOB_MENTION" "$1/SKILL.md" || return 1
    ! grep -Eq "$NUMBERED_RULE_NAME" "$1/SKILL.md"
}

planted_rules_check() {
    SANDBOX="${SANDBOX:-$(mktemp -d)}"
    rm -rf "$SANDBOX/ruleroot"
    mkdir -p "$SANDBOX/ruleroot/rules"
    local entry
    for entry in "$@"; do
        if [[ "$entry" == */ ]]; then mkdir -p "$SANDBOX/ruleroot/rules/$entry"; else : > "$SANDBOX/ruleroot/rules/$entry"; fi
    done
    rule_glob_matches_one_regular_file "$SANDBOX/ruleroot"
}

planted_rules_are_accepted() { planted_rules_check "$@"; }
planted_rules_are_rejected() { ! planted_rules_check "$@"; }

planted_symlinked_rules_check() {
    SANDBOX="${SANDBOX:-$(mktemp -d)}"
    rm -rf "$SANDBOX/ruleroot"
    mkdir -p "$SANDBOX/ruleroot/rules"
    : > "$SANDBOX/ruleroot/target.md"
    ln -s "$SANDBOX/ruleroot/$1" "$SANDBOX/ruleroot/rules/6_writing_style.md"
    rule_glob_matches_one_regular_file "$SANDBOX/ruleroot"
}

planted_dangling_rule_is_rejected() { ! planted_symlinked_rules_check missing.md; }
planted_symlinked_rule_is_rejected() { ! planted_symlinked_rules_check target.md; }

planted_rule_reference_check() {
    SANDBOX="${SANDBOX:-$(mktemp -d)}"
    rm -rf "$SANDBOX/rulemention"
    mkdir -p "$SANDBOX/rulemention"
    printf '%s\n' "$@" > "$SANDBOX/rulemention/SKILL.md"
    skill_refers_to_rule_by_glob "$SANDBOX/rulemention"
}

planted_rule_reference_is_accepted() { planted_rule_reference_check "$@"; }
planted_rule_reference_is_rejected() { ! planted_rule_reference_check "$@"; }

planted_missing_skill_is_rejected() {
    SANDBOX="${SANDBOX:-$(mktemp -d)}"
    mkdir -p "$SANDBOX/noskill"
    ! skill_refers_to_rule_by_glob "$SANDBOX/noskill"
}

# ── Excluded skills helpers ───────────────────────────────────────────────────

EXCLUDED_SKILLS=(shape-review-comments maintainx-pr-description mihai-changelogs commit)

text_names_skill() {
    grep -Eq "(^|[^[:alnum:]_-])$1([^[:alnum:]_-]|\$)" <<< "$2"
}

description_names_excluded_skills() {
    local description skill
    description="$(frontmatter_field description "$1")" || return 1
    for skill in "${EXCLUDED_SKILLS[@]}"; do
        text_names_skill "$skill" "$description" || return 1
    done
}

planted_excluded_check() {
    SANDBOX="${SANDBOX:-$(mktemp -d)}"
    mkdir -p "$SANDBOX/excluded"
    printf -- '---\nname: planted\ndescription: %s\n---\n%s\n' "$1" "${2:-body}" > "$SANDBOX/excluded/SKILL.md"
    description_names_excluded_skills "$SANDBOX/excluded/SKILL.md"
}

planted_excluded_are_accepted() { planted_excluded_check "$@"; }
planted_excluded_are_rejected() { ! planted_excluded_check "$@"; }

planted_missing_excluded_skill_file_is_rejected() {
    SANDBOX="${SANDBOX:-$(mktemp -d)}"
    mkdir -p "$SANDBOX/noexcluded"
    ! description_names_excluded_skills "$SANDBOX/noexcluded/SKILL.md"
}

# ── Shaper guard helpers ──────────────────────────────────────────────────────

SHAPER_BASE_SHA=106f522
UNRESOLVABLE_SHA=0000000000000000000000000000000000000001
EMPTY_TREE_SHA=4b825dc642cb6eb9a060e54bf8d69288fbee4904
PROTECTED_PATHS=(skills/shape-review-comments agents/shape-review-comments-agent.md skills/review-pipeline)

path_is_protected() {
    local protected
    for protected in "${PROTECTED_PATHS[@]}"; do
        [ "$1" = "$protected" ] || [[ "$1" == "$protected"/* ]] && return 0
    done
    return 1
}

shaper_base_entries() {
    local listing meta path
    listing="$(git -C "$1" ls-tree -r -t "$2" -- "${PROTECTED_PATHS[@]}")" || return 1
    [ -n "$listing" ] || return 1
    while IFS=$'\t' read -r meta path; do
        if path_is_protected "$path"; then printf '%s\t%s\t%s\n' "${meta%% *}" "${meta##* }" "$path"; fi
    done <<< "$listing"
}

shaper_base_inventory() {
    local entries mode oid path type target
    entries="$(shaper_base_entries "$@")" || return 1
    while IFS=$'\t' read -r mode oid path; do
        target=""
        case "$mode" in
            120000) type=link; target="$(git -C "$1" cat-file blob "$oid")" ;;
            100644|100755) type=file ;;
            040000) type=dir ;;
            *) type="mode-$mode" ;;
        esac
        printf '%s\t%s\t%s\n' "$type" "$path" "$target"
    done <<< "$entries" | LC_ALL=C sort
}

shaper_fs_inventory() {
    local entries path type target
    entries="$(cd "$1" && find "${PROTECTED_PATHS[@]}")" || return 1
    while IFS= read -r path; do
        target=""
        if [ -L "$1/$path" ]; then type=link; target="$(readlink "$1/$path")"
        elif [ -d "$1/$path" ]; then type=dir
        elif [ -f "$1/$path" ]; then type=file
        else type=other
        fi
        printf '%s\t%s\t%s\n' "$type" "$path" "$target"
    done <<< "$entries" | LC_ALL=C sort
}

shaper_matches_base_in_git() {
    local status
    git -C "$1" diff --quiet "$2" -- "${PROTECTED_PATHS[@]}" || return 1
    status="$(git -C "$1" status --porcelain --untracked-files=all -- "${PROTECTED_PATHS[@]}")" || return 1
    [ -z "$status" ]
}

shaper_inventory_matches_base() {
    local base filesystem
    base="$(shaper_base_inventory "$@")" || return 1
    filesystem="$(shaper_fs_inventory "$1")" || return 1
    [ "$base" = "$filesystem" ]
}

shaper_file_hashes_match_base() {
    local entries mode oid path
    entries="$(shaper_base_entries "$@")" || return 1
    while IFS=$'\t' read -r mode oid path; do
        case "$mode" in
            100644|100755) [ "$(git -C "$1" hash-object --no-filters -- "$path")" = "$oid" ] || return 1 ;;
        esac
    done <<< "$entries"
}

shaper_guard_holds() {
    local sha
    sha="$(git -C "$1" rev-parse --verify "${2:-$SHAPER_BASE_SHA}^{commit}")" || return 1
    shaper_matches_base_in_git "$1" "$sha" && shaper_inventory_matches_base "$1" "$sha" && shaper_file_hashes_match_base "$1" "$sha"
}

planted_shaper_check() {
    local checker="$1" mutation="$2" clone
    SANDBOX="${SANDBOX:-$(mktemp -d)}"
    clone="$SANDBOX/shaper-clone"
    rm -rf "$clone"
    git clone -q "$REPO_ROOT" "$clone" || return 1
    "$mutation" "$clone"
    "$checker" "$clone" "${3:-$SHAPER_BASE_SHA}"
}

planted_shaper_is_accepted() { planted_shaper_check "$@"; }
planted_shaper_is_rejected() { ! planted_shaper_check "$@"; }

leave_untouched() { :; }

plant_ignored_symlink() {
    printf 'skills/shape-review-comments/AGENTS.md\n' >> "$1/.git/info/exclude"
    ln -s SKILL.md "$1/skills/shape-review-comments/AGENTS.md"
}

plant_modified_file() { printf 'changed\n' >> "$1/skills/shape-review-comments/SKILL.md"; }

plant_untracked_file() { : > "$1/skills/review-pipeline/references/new.md"; }

plant_deleted_file() { rm "$1/agents/shape-review-comments-agent.md"; }

plant_committed_mode_change() {
    chmod +x "$1/skills/shape-review-comments/SKILL.md"
    git -C "$1" -c user.name=planted -c user.email=planted@example.invalid -c core.hooksPath=/dev/null commit -q -a -m planted
}

plant_hidden_modification() {
    plant_modified_file "$1"
    git -C "$1" update-index --assume-unchanged skills/shape-review-comments/SKILL.md
}

GOOD_EXAMPLES_LINE='Load references/examples.md when you need before and after pairs.'
GOOD_SURFACES_LINE='Load references/surfaces.md when choosing structure for a surface.'

# ── Install isolation helpers ─────────────────────────────────────────────────

INSTALLER="$REPO_ROOT/lib/install_skills.sh"
ISOLATION_ENV=()

physical_path() { (cd -P "$1" 2>/dev/null && pwd); }

prepare_isolation() {
    local root="$1" entry
    ISOLATION_ENV=(
        "HOME=$root/home"
        "CLAUDE_CONFIG_DIR=$root/claude"
        "CLAUDE_SKILLS_DIR=$root/claude/skills"
        "OPENCODE_CONFIG_DIR=$root/opencode"
        "OPENCODE_SKILLS_DIR=$root/opencode/skills"
        "PI_CODING_AGENT_DIR=$root/pi"
        "PI_SKILLS_DIR=$root/pi/skills"
    )
    for entry in "${ISOLATION_ENV[@]}"; do mkdir -p "${entry#*=}"; done
}

isolated_value() {
    local entry
    for entry in "${ISOLATION_ENV[@]}"; do
        if [ "${entry%%=*}" = "$1" ]; then echo "${entry#*=}"; return 0; fi
    done
    return 1
}

env_paths_are_inside() {
    local root="$1" entry resolved
    shift
    [ "$#" -gt 0 ] || return 1
    root="$(physical_path "$root")" || return 1
    for entry in "$@"; do
        resolved="$(physical_path "${entry#*=}")" || return 1
        [[ "$resolved" == "$root"/* ]] || return 1
    done
}

run_isolated_install() {
    env_paths_are_inside "$1" "${ISOLATION_ENV[@]}" || return 1
    env -i PATH="$PATH" "${ISOLATION_ENV[@]}" bash "$INSTALLER" "$REPO_ROOT/skills"
}

link_resolves_to() {
    local actual expected
    [ -L "$1" ] || return 1
    actual="$(physical_path "$1")" || return 1
    expected="$(physical_path "$2")" || return 1
    [ "$actual" = "$expected" ]
}

dirs_state() {
    local dir
    for dir in "$@"; do
        ls -ldA "$dir" 2>&1 || true
        ls -lA "$dir" 2>&1 || true
    done
}

live_skills_dirs() {
    echo "${CLAUDE_SKILLS_DIR:-${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills}"
    echo "${OPENCODE_SKILLS_DIR:-${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}/skills}"
    echo "${PI_SKILLS_DIR:-${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}/skills}"
}

live_state() {
    local dirs=() dir
    while IFS= read -r dir; do dirs+=("$dir"); done < <(live_skills_dirs)
    dirs_state "${dirs[@]}"
}

planted_guard_check() {
    local entries=() arg
    SANDBOX="${SANDBOX:-$(mktemp -d)}"
    rm -rf "$SANDBOX/guard"
    mkdir -p "$SANDBOX/guard/root/inside" "$SANDBOX/guard/root-evil" "$SANDBOX/guard/outside"
    ln -s "$SANDBOX/guard/outside" "$SANDBOX/guard/root/escape"
    for arg in "$@"; do entries+=("${arg%%=*}=$SANDBOX/guard/${arg#*=}"); done
    env_paths_are_inside "$SANDBOX/guard/root" "${entries[@]}"
}

planted_guard_accepts() { planted_guard_check "$@"; }
planted_guard_rejects() { ! planted_guard_check "$@"; }

planted_empty_guard_is_rejected() {
    SANDBOX="${SANDBOX:-$(mktemp -d)}"
    mkdir -p "$SANDBOX/guard/root"
    ! env_paths_are_inside "$SANDBOX/guard/root"
}

planted_link_check() {
    SANDBOX="${SANDBOX:-$(mktemp -d)}"
    rm -rf "$SANDBOX/links"
    mkdir -p "$SANDBOX/links/expected" "$SANDBOX/links/other"
    "$1" "$SANDBOX/links"
    link_resolves_to "$SANDBOX/links/link" "$SANDBOX/links/expected"
}

plant_link_to_expected() { ln -s "$1/expected" "$1/link"; }
plant_link_to_other() { ln -s "$1/other" "$1/link"; }
plant_copied_directory() { mkdir "$1/link"; }
plant_dangling_link() { ln -s "$1/missing" "$1/link"; }

planted_link_is_accepted() { planted_link_check "$@"; }
planted_link_is_rejected() { ! planted_link_check "$@"; }

planted_missing_expected_is_rejected() {
    SANDBOX="${SANDBOX:-$(mktemp -d)}"
    rm -rf "$SANDBOX/links"
    mkdir -p "$SANDBOX/links/other"
    ln -s "$SANDBOX/links/other" "$SANDBOX/links/link"
    ! link_resolves_to "$SANDBOX/links/link" "$SANDBOX/links/expected"
}

planted_state_check() {
    local before after
    SANDBOX="${SANDBOX:-$(mktemp -d)}"
    rm -rf "$SANDBOX/live"
    mkdir -p "$SANDBOX/live/present"
    before="$(dirs_state "$SANDBOX/live/present" "$SANDBOX/live/absent")"
    "$1" "$SANDBOX/live"
    after="$(dirs_state "$SANDBOX/live/present" "$SANDBOX/live/absent")"
    [ "$before" = "$after" ]
}

plant_added_entry() { ln -s target "$1/present/new"; }
plant_created_directory() { mkdir "$1/absent"; }

planted_state_is_stable() { planted_state_check leave_untouched; }
planted_state_change_is_detected() { ! planted_state_check "$1"; }

echo "writing-like-mihai skill"
echo ""

# ── Test 1: SKILL.md and its frontmatter ──────────────────────────────────────

assert "ruby is available to parse frontmatter" ruby_is_available
assert "SKILL.md exists" [ -f "$SKILL_MD" ]
assert "frontmatter parses as YAML" frontmatter_field name
assert "name equals the directory name" name_is_directory_name
assert "description is non-empty" description_is_non_empty
assert "description is under 1024 characters" description_is_under_limit
assert "description is third person" description_is_third_person

# ── Test 2: no em-dashes in skill markdown ────────────────────────────────────

assert "skill markdown contains no em-dash" markdown_has_no_em_dash "$SKILL_DIR"
assert "planted em-dash in a copy is detected" planted_em_dash_is_detected

# ── Test 3: links and file inventory ──────────────────────────────────────────

assert "every references link in SKILL.md resolves to a file" skill_links_resolve "$SKILL_DIR"
assert "no reference file links onward to another reference" references_have_no_onward_links "$SKILL_DIR"
assert "skill has exactly SKILL.md and the two references" skill_has_exactly_three_files "$SKILL_DIR"
assert "planted dangling link is detected" planted_dangling_link_is_detected
assert "planted onward reference link is detected" planted_onward_link_is_detected

# ── Test 4: contents, mentions, and size ─────────────────────────────────────

assert "references over 100 lines have a table of contents in the first 30 lines" long_references_have_contents "$SKILL_DIR"
assert "SKILL.md mentions each reference once with a reason to load it" skill_mentions_each_reference_with_reason "$SKILL_DIR"
assert "SKILL.md is at most 120 lines" skill_is_at_most_120_lines "$SKILL_DIR"
assert "planted 101-line reference without contents is rejected" planted_reference_is_rejected 101 0 ""
assert "planted 101-line reference without contents or a final newline is rejected" planted_reference_is_rejected 101 0 "" unterminated
assert "planted 101-line reference with a table of contents on line 1 is accepted" planted_reference_is_accepted 101 1 "## Table of contents\n- one"
assert "planted 101-line reference with a table of contents on line 30 is accepted" planted_reference_is_accepted 101 30 "## Table of contents\n- one"
assert "planted 101-line reference with a table of contents on line 31 is rejected" planted_reference_is_rejected 101 31 "## Table of contents\n- one"
assert "planted 101-line reference with a bare contents heading and no list is rejected" planted_reference_is_rejected 101 1 "## Contents"
assert "planted 101-line reference with a wrong heading is rejected" planted_reference_is_rejected 101 1 "## Why we discuss contents of cups\n- one"
assert "planted 100-line reference without contents is accepted" planted_reference_is_accepted 100 0 ""
assert "planted good mention lines are accepted" planted_mentions_are_accepted "$GOOD_EXAMPLES_LINE" "$GOOD_SURFACES_LINE"
assert "planted missing mention is rejected" planted_mentions_are_rejected "$GOOD_EXAMPLES_LINE"
assert "planted double mention is rejected" planted_mentions_are_rejected "$GOOD_EXAMPLES_LINE" "$GOOD_SURFACES_LINE" "$GOOD_SURFACES_LINE"
assert "planted mention without Load before the path is rejected" planted_mentions_are_rejected "$GOOD_EXAMPLES_LINE" "Look at this (for real) references/surfaces.md"
assert "planted mention without a reason after the path is rejected" planted_mentions_are_rejected "$GOOD_EXAMPLES_LINE" "Load references/surfaces.md when ok."
assert "planted mention with the reason on the next line is rejected" planted_mentions_are_rejected "$GOOD_EXAMPLES_LINE" "Load references/surfaces.md" "when choosing structure for a surface."
assert "planted mention through a longer path prefix is rejected" planted_mentions_are_rejected "$GOOD_EXAMPLES_LINE" "Load xreferences/surfaces.md when choosing structure for a surface."
assert "planted mention with a .md.bak suffix is rejected" planted_mentions_are_rejected "$GOOD_EXAMPLES_LINE" "Load references/surfaces.md.bak when choosing structure for a surface."
assert "planted 120-line SKILL.md is accepted" planted_skill_is_accepted 120
assert "planted 121-line SKILL.md is rejected" planted_skill_is_rejected 121
assert "planted 120-line SKILL.md without a final newline is accepted" planted_skill_is_accepted 120 unterminated
assert "planted 121-line SKILL.md without a final newline is rejected" planted_skill_is_rejected 121 unterminated

# ── Test 5: rule pointer resolves ────────────────────────────────────────────

assert "rule glob matches exactly one regular file in the repo" rule_glob_matches_one_regular_file "$REPO_ROOT"
assert "SKILL.md refers to the rule by glob and not by a numbered filename" skill_refers_to_rule_by_glob "$SKILL_DIR"
assert "planted single regular rule file is accepted" planted_rules_are_accepted 6_writing_style.md
assert "planted unnumbered rule file is accepted" planted_rules_are_accepted writing_style.md
assert "planted rules with no match are rejected" planted_rules_are_rejected 1_other.md
assert "planted rules with two matches are rejected" planted_rules_are_rejected 6_writing_style.md 7_writing_style.md
assert "planted rules with a directory match are rejected" planted_rules_are_rejected 6_writing_style.md/
assert "planted rules with a file and a directory match are rejected" planted_rules_are_rejected 6_writing_style.md 7_writing_style.md/
assert "planted rules with a nested match only are rejected" planted_rules_are_rejected nested/ nested/6_writing_style.md
assert "planted rules with a longer suffix are rejected" planted_rules_are_rejected 6_writing_style.md.bak
assert "planted dangling symlink rule is rejected" planted_dangling_rule_is_rejected
assert "planted symlinked rule is rejected" planted_symlinked_rule_is_rejected
assert "planted SKILL.md with the literal glob is accepted" planted_rule_reference_is_accepted "Follow the rule at rules/*writing_style.md for style."
assert "planted SKILL.md with the glob in backticks and a full stop is accepted" planted_rule_reference_is_accepted 'Rule 6 lives at `rules/*writing_style.md`.' 'Style comes first.'
assert "planted SKILL.md with the glob at the end of a sentence is accepted" planted_rule_reference_is_accepted "Follow rules/*writing_style.md."
assert "planted SKILL.md with a numbered filename only is rejected" planted_rule_reference_is_rejected "Follow rules/6_writing_style.md for style."
assert "planted SKILL.md with the glob and a numbered filename is rejected" planted_rule_reference_is_rejected "Follow rules/*writing_style.md for style." "See also 10_writing_style.md."
assert "planted SKILL.md without any mention is rejected" planted_rule_reference_is_rejected "Write plainly."
assert "planted SKILL.md with the glob missing its star is rejected" planted_rule_reference_is_rejected "Follow rules/writing_style.md for style."
assert "planted SKILL.md with the glob through a longer prefix is rejected" planted_rule_reference_is_rejected "Follow xrules/*writing_style.md for style."
assert "planted SKILL.md with the glob and a .bak suffix is rejected" planted_rule_reference_is_rejected "Follow rules/*writing_style.md.bak for style."
assert "planted missing SKILL.md is rejected" planted_missing_skill_is_rejected

# ── Test 6: description names the excluded skills ────────────────────────────

assert "description names shape-review-comments, maintainx-pr-description, mihai-changelogs and commit" description_names_excluded_skills "$SKILL_MD"
assert "planted description with all four names is accepted" planted_excluded_are_accepted "Not for shape-review-comments, maintainx-pr-description, mihai-changelogs, or commit."
assert "planted description with backticks, parentheses and the name at the end is accepted" planted_excluded_are_accepted 'Skips `shape-review-comments` and (maintainx-pr-description) plus mihai-changelogs or commit'
assert "planted description without shape-review-comments is rejected" planted_excluded_are_rejected "Not for maintainx-pr-description, mihai-changelogs, or commit."
assert "planted description without maintainx-pr-description is rejected" planted_excluded_are_rejected "Not for shape-review-comments, mihai-changelogs, or commit."
assert "planted description without mihai-changelogs is rejected" planted_excluded_are_rejected "Not for shape-review-comments, maintainx-pr-description, or commit."
assert "planted description without commit is rejected" planted_excluded_are_rejected "Not for shape-review-comments, maintainx-pr-description, or mihai-changelogs."
assert "planted description with committed instead of commit is rejected" planted_excluded_are_rejected "Not for shape-review-comments, maintainx-pr-description, mihai-changelogs, or committed text."
assert "planted description with commits instead of commit is rejected" planted_excluded_are_rejected "Not for shape-review-comments, maintainx-pr-description, mihai-changelogs, or commits."
assert "planted description with commit-agent instead of commit is rejected" planted_excluded_are_rejected "Not for shape-review-comments, maintainx-pr-description, mihai-changelogs, or commit-agent."
assert "planted description with pre-commit instead of commit is rejected" planted_excluded_are_rejected "Not for shape-review-comments, maintainx-pr-description, mihai-changelogs, or pre-commit."
assert "planted description with a longer name instead of shape-review-comments is rejected" planted_excluded_are_rejected "Not for shape-review-comments-agent, maintainx-pr-description, mihai-changelogs, or commit."
assert "planted description missing a name that the body mentions is rejected" planted_excluded_are_rejected "Not for shape-review-comments, maintainx-pr-description, or mihai-changelogs." "Hand off to commit for commit messages."
assert "planted description with no names while the body names all four is rejected" planted_excluded_are_rejected "Drafts prose in Mihai voice." "Not for shape-review-comments, maintainx-pr-description, mihai-changelogs, or commit."
assert "planted missing SKILL.md is rejected by the excluded skills check" planted_missing_excluded_skill_file_is_rejected

# ── Test 7: shaper guard ─────────────────────────────────────────────────────

assert "shaper paths match base $SHAPER_BASE_SHA in the real worktree" shaper_guard_holds "$REPO_ROOT"
assert "planted untouched clone is accepted" planted_shaper_is_accepted shaper_guard_holds leave_untouched
assert "planted ignored AGENTS.md symlink under the shaper is rejected" planted_shaper_is_rejected shaper_guard_holds plant_ignored_symlink
assert "planted modified tracked file is rejected" planted_shaper_is_rejected shaper_guard_holds plant_modified_file
assert "planted untracked file is rejected" planted_shaper_is_rejected shaper_guard_holds plant_untracked_file
assert "planted deleted file is rejected" planted_shaper_is_rejected shaper_guard_holds plant_deleted_file
assert "planted modification hidden from git is rejected" planted_shaper_is_rejected shaper_guard_holds plant_hidden_modification
assert "planted unresolvable base SHA is rejected" planted_shaper_is_rejected shaper_guard_holds leave_untouched "$UNRESOLVABLE_SHA"
assert "planted committed mode change is rejected" planted_shaper_is_rejected shaper_guard_holds plant_committed_mode_change
assert "git checks accept an untouched clone" planted_shaper_is_accepted shaper_matches_base_in_git leave_untouched
assert "git checks cannot see a planted ignored symlink" planted_shaper_is_accepted shaper_matches_base_in_git plant_ignored_symlink
assert "git checks cannot see a planted hidden modification" planted_shaper_is_accepted shaper_matches_base_in_git plant_hidden_modification
assert "git checks reject a planted committed mode change" planted_shaper_is_rejected shaper_matches_base_in_git plant_committed_mode_change
assert "git checks reject a planted modified file" planted_shaper_is_rejected shaper_matches_base_in_git plant_modified_file
assert "git checks reject a planted untracked file" planted_shaper_is_rejected shaper_matches_base_in_git plant_untracked_file
assert "git checks reject a planted deleted file" planted_shaper_is_rejected shaper_matches_base_in_git plant_deleted_file
assert "inventory accepts an untouched clone" planted_shaper_is_accepted shaper_inventory_matches_base leave_untouched
assert "inventory accepts a planted hidden modification" planted_shaper_is_accepted shaper_inventory_matches_base plant_hidden_modification
assert "inventory rejects a planted ignored symlink" planted_shaper_is_rejected shaper_inventory_matches_base plant_ignored_symlink
assert "inventory rejects a planted untracked file" planted_shaper_is_rejected shaper_inventory_matches_base plant_untracked_file
assert "inventory rejects a planted deleted file" planted_shaper_is_rejected shaper_inventory_matches_base plant_deleted_file
assert "inventory rejects an empty base listing" planted_shaper_is_rejected shaper_inventory_matches_base leave_untouched "$EMPTY_TREE_SHA"
assert "hash check accepts an untouched clone" planted_shaper_is_accepted shaper_file_hashes_match_base leave_untouched
assert "hash check accepts a planted ignored symlink" planted_shaper_is_accepted shaper_file_hashes_match_base plant_ignored_symlink
assert "hash check rejects a planted hidden modification" planted_shaper_is_rejected shaper_file_hashes_match_base plant_hidden_modification
assert "hash check rejects a planted deleted file" planted_shaper_is_rejected shaper_file_hashes_match_base plant_deleted_file
assert "hash check rejects an empty base listing" planted_shaper_is_rejected shaper_file_hashes_match_base leave_untouched "$EMPTY_TREE_SHA"

# ── Test 8: install isolation ────────────────────────────────────────────────

SANDBOX="${SANDBOX:-$(mktemp -d)}"
ISOLATION_ROOT="$(mktemp -d "$SANDBOX/isolation.XXXXXX")"
prepare_isolation "$ISOLATION_ROOT"
LIVE_STATE_BEFORE="$(live_state)"

assert "every install destination resolves inside the temp dir" env_paths_are_inside "$ISOLATION_ROOT" "${ISOLATION_ENV[@]}"
assert "planted destinations inside the root are accepted" planted_guard_accepts A=root/inside B=root/inside
assert "planted destination outside the root is rejected" planted_guard_rejects A=root/inside B=outside
assert "planted destination in a sibling with the root as name prefix is rejected" planted_guard_rejects A=root/inside B=root-evil
assert "planted destination escaping through a symlink is rejected" planted_guard_rejects A=root/inside B=root/escape
assert "planted destination missing on disk is rejected" planted_guard_rejects A=root/inside B=root/missing
assert "planted destination equal to the root is rejected" planted_guard_rejects A=root/inside B=root
assert "planted empty destination list is rejected" planted_empty_guard_is_rejected
assert "installer runs against the worktree skills inside the temp dir" run_isolated_install "$ISOLATION_ROOT"
assert "installer links writing-like-mihai in the Claude skills dir" link_resolves_to "$(isolated_value CLAUDE_SKILLS_DIR)/$SKILL_NAME" "$SKILL_DIR"
assert "installer links writing-like-mihai in the OpenCode skills dir" link_resolves_to "$(isolated_value OPENCODE_SKILLS_DIR)/$SKILL_NAME" "$SKILL_DIR"
assert "installer links writing-like-mihai in the pi skills dir" link_resolves_to "$(isolated_value PI_SKILLS_DIR)/$SKILL_NAME" "$SKILL_DIR"
assert "planted symlink to the expected directory is accepted" planted_link_is_accepted plant_link_to_expected
assert "planted symlink to another directory is rejected" planted_link_is_rejected plant_link_to_other
assert "planted copied directory instead of a symlink is rejected" planted_link_is_rejected plant_copied_directory
assert "planted dangling symlink is rejected" planted_link_is_rejected plant_dangling_link
assert "planted symlink with a missing expected directory is rejected" planted_missing_expected_is_rejected
assert "live skills dirs are unchanged by the install" [ "$(live_state)" = "$LIVE_STATE_BEFORE" ]
assert "planted untouched live dirs are reported as unchanged" planted_state_is_stable
assert "planted added entry in a live dir is detected" planted_state_change_is_detected plant_added_entry
assert "planted created live dir is detected" planted_state_change_is_detected plant_created_directory

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo "Passed: $PASS  Failed: $FAIL"
[ "$FAIL" -eq 0 ]
