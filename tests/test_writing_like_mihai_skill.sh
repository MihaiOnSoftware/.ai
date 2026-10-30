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
    ' "$SKILL_MD" "$1"
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

GOOD_EXAMPLES_LINE='Load references/examples.md when you need before and after pairs.'
GOOD_SURFACES_LINE='Load references/surfaces.md when choosing structure for a surface.'

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

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo "Passed: $PASS  Failed: $FAIL"
[ "$FAIL" -eq 0 ]
