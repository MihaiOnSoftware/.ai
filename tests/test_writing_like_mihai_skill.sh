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
    if "$@" 2>/dev/null; then pass "$desc"; else fail "$desc"; fi
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

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo "Passed: $PASS  Failed: $FAIL"
[ "$FAIL" -eq 0 ]
