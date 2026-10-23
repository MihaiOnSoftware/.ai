#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="${MONITOR_REVIEW_SCRIPT:-$SCRIPT_DIR/../skills/monitor-gh-pr/scripts/monitor-gh-pr-review.sh}"

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
  *"/compare/"*)            cat "$FIX/compare" ;;
  "pr view"*)               cat "$FIX/pr_meta" ;;
  "api user"*)              echo "authed-user" ;;
  *) echo "unexpected gh call: $*" >&2; exit 2 ;;
esac
EOF
printf '#!/usr/bin/env bash\nexit 1\n' > "$BIN/sleep"
chmod +x "$BIN/gh" "$BIN/sleep"

pr_meta() {
    local state="$1" head="$2" requested="${3:-}"
    local reviewers="[]"
    if [[ -n "$requested" ]]; then
        reviewers=$(printf '%s' "$requested" | awk -F, '{
            printf "["
            for (i = 1; i <= NF; i++) printf "%s{\"login\":\"%s\"}", (i > 1 ? "," : ""), $i
            printf "]"
        }')
    fi
    printf '{"state":"%s","headRefOid":"%s","reviewRequests":%s}\n' "$state" "$head" "$reviewers" > "$FIX/pr_meta"
}

reset_state() {
    rm -rf "$TEST_DIR/state"
    mkdir -p "$TEST_DIR/state"
    : > "$FIX/regular"
    : > "$FIX/review"
    : > "$FIX/pr_reviews"
    : > "$FIX/compare"
    pr_meta OPEN sha-1
}

OUT="$TEST_DIR/out"
run_monitor() {
    set +e
    PATH="$BIN:$PATH" FIX="$FIX" MONITOR_GH_PR_STATE_ROOT="$TEST_DIR/state" \
        bash "$SCRIPT" owner/repo 42 --reviewer mihai > "$OUT" 2>/dev/null
    STATUS=$?
    set -e
}

reported() { grep -q "$1" "$OUT"; }

echo "monitor-gh-pr-review.sh"
echo ""

# ── Baseline ──────────────────────────────────────────────────────────────────

reset_state
run_monitor
assert "baseline: first run is idle" [ "$STATUS" -eq 1 ]

# ── Merge / close ─────────────────────────────────────────────────────────────

reset_state
run_monitor
pr_meta MERGED sha-1
run_monitor
assert "merged PR is reported" reported "PR is MERGED"
assert "merged PR exits actionable" [ "$STATUS" -eq 0 ]

reset_state
run_monitor
pr_meta CLOSED sha-1
run_monitor
assert "closed PR is reported" reported "PR is CLOSED"

# ── New commits ───────────────────────────────────────────────────────────────

reset_state
run_monitor
pr_meta OPEN sha-2
echo '  •  abc123def45 Fix the thing' > "$FIX/compare"
run_monitor
assert "new head is reported" reported "New commit(s) — head sha-1 → sha-2"
assert "new commit subject is listed" reported "Fix the thing"

run_monitor
assert "same head is not re-reported" [ "$STATUS" -eq 1 ]

pr_meta OPEN sha-3
: > "$FIX/compare"
run_monitor
assert "unreachable compare falls back to force-push note" reported "force-push or rebase: sha-2 → sha-3"

# ── Review requests ───────────────────────────────────────────────────────────

reset_state
run_monitor
pr_meta OPEN sha-1 other-person
run_monitor
assert "reviewer-set change is reported" reported "Review requests changed — was \[none\], now \[other-person\]"
assert_not "other reviewer is not flagged as re-review" reported "Re-review requested from mihai"

pr_meta OPEN sha-1 mihai,other-person
run_monitor
assert "newly requested watched reviewer is flagged" reported "Re-review requested from mihai"

run_monitor
assert "unchanged reviewer set is not re-reported" [ "$STATUS" -eq 1 ]

pr_meta OPEN sha-1 other-person
run_monitor
assert "reviewer removal is reported without the re-review flag" reported "now \[other-person\]"
assert_not "reviewer removal does not flag re-review" reported "Re-review requested from mihai"

# ── Comments and reviews ──────────────────────────────────────────────────────

reset_state
printf '101\n' > "$FIX/regular"
run_monitor
assert "existing comments are not re-reported" [ "$STATUS" -eq 1 ]

printf '101\n102\n' > "$FIX/regular"
echo 7 > "$FIX/review"
echo 9 > "$FIX/pr_reviews"
run_monitor
assert "new PR comment is reported" reported "1 new PR comment(s)"
assert "new inline review comment is reported" reported "1 new inline review comment(s)"
assert "new PR review is reported" reported "1 new PR review(s)"

run_monitor
assert "handled comments are not re-reported" [ "$STATUS" -eq 1 ]

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo "Passed: $PASS  Failed: $FAIL"
[ "$FAIL" -eq 0 ]
