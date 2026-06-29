#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_SCRIPT="$SCRIPT_DIR/../lib/build_agents_md.sh"

PASS=0
FAIL=0

pass() { echo "✓ $1"; PASS=$((PASS + 1)); }
fail() { echo "✗ $1"; FAIL=$((FAIL + 1)); }

assert() {
    local desc="$1"; shift
    if "$@" 2>/dev/null; then pass "$desc"; else fail "$desc"; fi
}

assert_not() {
    local desc="$1"; shift
    if ! "$@" 2>/dev/null; then pass "$desc"; else fail "$desc"; fi
}

# ── Setup ─────────────────────────────────────────────────────────────────────

TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT

RULES_DIR="$TEST_DIR/rules"
OUTPUT="$TEST_DIR/AGENTS.md"
mkdir -p "$RULES_DIR"

printf '# Rule One\n\nContent of rule one.\n' > "$RULES_DIR/1_first.md"
printf '# Rule Two\n\nContent of rule two.\n' > "$RULES_DIR/2_second.md"
printf '# Rule Three\n\nContent of rule three.\n' > "$RULES_DIR/3_third.md"

# ── Tests ─────────────────────────────────────────────────────────────────────

echo "build_agents_md.sh"
echo ""

"$BUILD_SCRIPT" "$RULES_DIR" "$OUTPUT" > /dev/null

assert "creates the output file" [ -f "$OUTPUT" ]
assert "contains content from rule 1" grep -q "Rule One" "$OUTPUT"
assert "contains content from rule 2" grep -q "Rule Two" "$OUTPUT"
assert "contains content from rule 3" grep -q "Rule Three" "$OUTPUT"

pos1=$(grep -n "Rule One" "$OUTPUT" | head -1 | cut -d: -f1)
pos2=$(grep -n "Rule Two" "$OUTPUT" | head -1 | cut -d: -f1)
pos3=$(grep -n "Rule Three" "$OUTPUT" | head -1 | cut -d: -f1)
assert "rule 1 appears before rule 2" [ "$pos1" -lt "$pos2" ]
assert "rule 2 appears before rule 3" [ "$pos2" -lt "$pos3" ]

first_content="$(cat "$OUTPUT")"
"$BUILD_SCRIPT" "$RULES_DIR" "$OUTPUT" > /dev/null
second_content="$(cat "$OUTPUT")"
assert "is idempotent" [ "$first_content" = "$second_content" ]

printf '# Rule Four\n\nContent of rule four.\n' > "$RULES_DIR/4_fourth.md"
"$BUILD_SCRIPT" "$RULES_DIR" "$OUTPUT" > /dev/null
assert "picks up newly added rule files" grep -q "Rule Four" "$OUTPUT"

rm "$RULES_DIR/2_second.md"
"$BUILD_SCRIPT" "$RULES_DIR" "$OUTPUT" > /dev/null
assert_not "omits removed rule files" grep -q "Rule Two" "$OUTPUT"
assert "remaining rules still present after removal" grep -q "Rule One" "$OUTPUT"

assert_not "fails when rules dir does not exist" "$BUILD_SCRIPT" "$TEST_DIR/nonexistent" "$OUTPUT"

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
