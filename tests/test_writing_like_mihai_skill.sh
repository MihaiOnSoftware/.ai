#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILL_NAME="writing-like-mihai"
SKILL_DIR="$REPO_ROOT/skills/$SKILL_NAME"
SKILL_MD="$SKILL_DIR/SKILL.md"

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
    expected="$(printf './SKILL.md\n./references/examples.md\n./references/surfaces.md')"
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

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo "Passed: $PASS  Failed: $FAIL"
[ "$FAIL" -eq 0 ]
