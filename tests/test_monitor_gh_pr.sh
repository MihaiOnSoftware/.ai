#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="${MONITOR_SCRIPT:-$SCRIPT_DIR/../skills/monitor-gh-pr/scripts/monitor-gh-pr.sh}"

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
# `gh` is stubbed with a PATH shim that serves fixture files.
# `sleep` is stubbed to exit 1, so under `set -e` an idle poll ends the run:
#   exit 0 → the script reported something actionable
#   exit 1 → the script found nothing new on its first poll

TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT

BIN="$TEST_DIR/bin"
FIX="$TEST_DIR/fixtures"
mkdir -p "$BIN" "$FIX"

cat > "$BIN/gh" <<'EOF'
#!/usr/bin/env bash
case "$*" in
  *"/issues/"*"/comments"*) cat "$FIX/regular" ;;
  *"/pulls/"*"/comments"*)  cat "$FIX/review" ;;
  *"/pulls/"*"/reviews"*)   cat "$FIX/pr_reviews" ;;
  "pr checks"*)             cat "$FIX/checks" ;;
  "pr view"*)               cat "$FIX/head_sha" ;;
  *) echo "unexpected gh call: $*" >&2; exit 2 ;;
esac
EOF
printf '#!/usr/bin/env bash\nexit 1\n' > "$BIN/sleep"
chmod +x "$BIN/gh" "$BIN/sleep"

reset_state() {
    rm -rf "$TEST_DIR/state"
    mkdir -p "$TEST_DIR/state"
    : > "$FIX/regular"
    : > "$FIX/review"
    : > "$FIX/pr_reviews"
    echo '[]' > "$FIX/checks"
    echo 'sha-1' > "$FIX/head_sha"
}

OUT="$TEST_DIR/out"
run_monitor() {
    set +e
    PATH="$BIN:$PATH" FIX="$FIX" MONITOR_GH_PR_STATE_ROOT="$TEST_DIR/state" \
        bash "$SCRIPT" owner/repo 42 > "$OUT" 2>/dev/null
    STATUS=$?
    set -e
}

reported() { grep -q "$1" "$OUT"; }

echo "monitor-gh-pr.sh"
echo ""

# ── Comments: empty baseline ──────────────────────────────────────────────────

reset_state
run_monitor
assert "empty baseline: first run is idle" [ "$STATUS" -eq 1 ]

echo 101 > "$FIX/regular"
run_monitor
assert "empty baseline: first comment is reported" [ "$STATUS" -eq 0 ]
assert "empty baseline: count is 1" reported "1 new PR comment(s)"

# ── Comments: non-empty baseline ──────────────────────────────────────────────

reset_state
printf '101\n102\n' > "$FIX/regular"
run_monitor
assert "existing comments are not re-reported" [ "$STATUS" -eq 1 ]

printf '101\n102\n103\n' > "$FIX/regular"
run_monitor
assert "only the new comment is counted" reported "1 new PR comment(s)"

reset_state
echo 7 > "$FIX/review"
echo 9 > "$FIX/pr_reviews"
run_monitor
echo 8 >> "$FIX/review"
echo 10 >> "$FIX/pr_reviews"
run_monitor
assert "new inline review comment is reported" reported "1 new inline review comment(s)"
assert "new PR review is reported" reported "1 new PR review(s)"

# ── CI: pass ──────────────────────────────────────────────────────────────────

reset_state
echo '[{"name":"lint","state":"COMPLETED","bucket":"pass"}]' > "$FIX/checks"
run_monitor
assert "CI pass is reported" reported "CI Passed — 1 of 1 checks"

run_monitor
assert "CI pass is not re-reported on the same head" [ "$STATUS" -eq 1 ]

echo 'sha-2' > "$FIX/head_sha"
run_monitor
assert "CI pass is reported again after a new push" reported "CI Passed — 1 of 1 checks"

# ── CI: fail ──────────────────────────────────────────────────────────────────

reset_state
echo '[{"name":"lint","state":"COMPLETED","bucket":"fail"}]' > "$FIX/checks"
run_monitor
assert "CI fail is reported" reported "CI Failing — 1 of 1 checks failed"

run_monitor
assert "same CI fail is not re-reported on the same head" [ "$STATUS" -eq 1 ]

echo 'sha-2' > "$FIX/head_sha"
run_monitor
assert "same CI fail is reported again after a new push" reported "CI Failing — 1 of 1 checks failed"

echo '[{"name":"lint","state":"COMPLETED","bucket":"fail"},{"name":"unit","state":"COMPLETED","bucket":"fail"}]' > "$FIX/checks"
run_monitor
assert "changed failing set is reported on the same head" reported "CI Failing — 2 of 2 checks failed"

# ── CI: fail signature is not fooled by commas in check names ─────────────────

reset_state
echo '[{"name":"a,b","state":"COMPLETED","bucket":"fail"}]' > "$FIX/checks"
run_monitor
echo '[{"name":"a","state":"COMPLETED","bucket":"fail"},{"name":"b","state":"COMPLETED","bucket":"fail"}]' > "$FIX/checks"
run_monitor
assert "comma-containing check name does not collide with split names" reported "CI Failing — 2 of 2 checks failed"

# ── CI: fail → pass → fail transitions ───────────────────────────────────────

reset_state
echo '[{"name":"lint","state":"COMPLETED","bucket":"fail"}]' > "$FIX/checks"
run_monitor
echo '[{"name":"lint","state":"COMPLETED","bucket":"pass"}]' > "$FIX/checks"
run_monitor
assert "fail then pass on the same head reports the pass" reported "CI Passed — 1 of 1 checks"
echo '[{"name":"lint","state":"COMPLETED","bucket":"fail"}]' > "$FIX/checks"
run_monitor
assert "pass then fail on the same head reports the fail" reported "CI Failing — 1 of 1 checks failed"

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo "Passed: $PASS  Failed: $FAIL"
[ "$FAIL" -eq 0 ]
