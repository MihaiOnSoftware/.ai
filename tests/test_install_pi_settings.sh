#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

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

json_get() { node -e "console.log(JSON.stringify(JSON.parse(require('fs').readFileSync('$1','utf8'))$2))"; }

# ── Setup ─────────────────────────────────────────────────────────────────────

TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT

SOURCE="$TEST_DIR/pi.jsonc"
SETTINGS="$TEST_DIR/settings.json"
BACKUP="$SETTINGS.install-$(date +%Y%m%d).bak"

cat > "$SOURCE" <<'EOF'
{
  // comment to prove jsonc parsing
  "packages": ["npm:x"],
  "settings": {
    "contextPrune": { "enabled": true, "pruneOn": "agent-message" }
  }
}
EOF

run_install() { PI_SETTINGS_FILE="$SETTINGS" bash "$LIB_DIR/install_pi_settings.sh" "$SOURCE" > /dev/null 2>&1; }
run_uninstall() { PI_SETTINGS_FILE="$SETTINGS" bash "$LIB_DIR/uninstall_pi_settings.sh" "$SOURCE" > /dev/null 2>&1; }

echo "install_pi_settings.sh"
echo ""

# ── Install into existing settings ───────────────────────────────────────────

echo '{"defaultProvider":"anthropic","contextPrune":{"enabled":false,"minBatchChars":500}}' > "$SETTINGS"
run_install

assert "settings file is valid JSON after install" node -e "JSON.parse(require('fs').readFileSync('$SETTINGS','utf8'))"
assert "declared value overrides existing" [ "$(json_get "$SETTINGS" .contextPrune.enabled)" = "true" ]
assert "declared subkey is merged in" [ "$(json_get "$SETTINGS" .contextPrune.pruneOn)" = '"agent-message"' ]
assert "existing subkey survives deep merge" [ "$(json_get "$SETTINGS" .contextPrune.minBatchChars)" = "500" ]
assert "unmanaged top-level key untouched" [ "$(json_get "$SETTINGS" .defaultProvider)" = '"anthropic"' ]

# ── Backup ────────────────────────────────────────────────────────────────────

assert "backup file created" [ -f "$BACKUP" ]
assert "backup holds pre-change content" grep -q '"enabled":false' "$BACKUP"
assert_not "no temp file left behind" ls "$SETTINGS".tmp.* 

# ── Idempotence ───────────────────────────────────────────────────────────────

before="$(cat "$SETTINGS")"
run_install
assert "re-install is idempotent" [ "$before" = "$(cat "$SETTINGS")" ]

# ── Uninstall ────────────────────────────────────────────────────────────────

run_uninstall
assert_not "managed key removed on uninstall" grep -q contextPrune "$SETTINGS"
assert "unmanaged key survives uninstall" grep -q defaultProvider "$SETTINGS"
assert "settings file is valid JSON after uninstall" node -e "JSON.parse(require('fs').readFileSync('$SETTINGS','utf8'))"

# ── Missing settings file ────────────────────────────────────────────────────

assert "uninstall writes its own backup" [ -f "$SETTINGS.uninstall-$(date +%Y%m%d).bak" ]

rm -f "$SETTINGS" "$BACKUP"
run_install
assert "creates settings file when missing" [ -f "$SETTINGS" ]
assert "created file is valid JSON" node -e "JSON.parse(require('fs').readFileSync('$SETTINGS','utf8'))"
assert "created file has declared keys" grep -q contextPrune "$SETTINGS"

# ── Corrupt settings file ────────────────────────────────────────────────────

echo '{"broken": ' > "$SETTINGS"
cp "$SETTINGS" "$TEST_DIR/corrupt-copy"
assert_not "refuses to run against corrupt settings" run_install
assert "corrupt file left unmodified" diff -q "$SETTINGS" "$TEST_DIR/corrupt-copy"

# ── No settings key in source ────────────────────────────────────────────────

echo '{"packages":["npm:x"]}' > "$SOURCE"
echo '{"defaultProvider":"anthropic"}' > "$SETTINGS"
before="$(cat "$SETTINGS")"
run_install
assert "no-op when source declares no settings" [ "$before" = "$(cat "$SETTINGS")" ]

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
