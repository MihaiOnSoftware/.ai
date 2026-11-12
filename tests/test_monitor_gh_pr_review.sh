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
  "api graphql"*)           cat "$FIX/threads" ;;
  *"/issues/"*"/comments"*) cat "$FIX/regular" ;;
  *"/pulls/"*"/comments"*)  cat "$FIX/review" ;;
  *"/pulls/"*"/reviews"*)   cat "$FIX/pr_reviews" ;;
  *"/compare/"*)            cat "$FIX/compare"; [ ! -e "$FIX/compare_fails" ] ;;
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

# Each argument is one review: "<id> <login> <state> <commit>", oldest first.
pr_reviews() {
    printf '%s\n' "$@" | jq -Rn '[inputs | select(length > 0) | split(" ")
        | {id: (.[0] | tonumber), user: {login: .[1]}, state: .[2], commit_id: .[3]}]' > "$FIX/pr_reviews"
}

# Each argument is one review thread: "<resolved> <outdated> <path> <line> <comments> <starter> <body>".
threads() {
    printf '%s\n' "$@" | jq -Rn '[inputs | select(length > 0) | split(" ")
        | {isResolved: (.[0] == "true"), isOutdated: (.[1] == "true"), path: .[2],
           line: (if .[1] == "true" then null else (.[3] | tonumber) end), originalLine: (.[3] | tonumber),
           comments: {totalCount: (.[4] | tonumber), nodes: [{author: {login: .[5]}, body: (.[6:] | join(" "))}]}}]
        | {data: {repository: {pullRequest: {reviewThreads: {nodes: .}}}}}' > "$FIX/threads"
}

reset_state() {
    rm -rf "$TEST_DIR/state"
    mkdir -p "$TEST_DIR/state"
    : > "$FIX/regular"
    : > "$FIX/review"
    : > "$FIX/compare"
    rm -f "$FIX/compare_fails"
    pr_reviews
    threads
    pr_meta OPEN sha-1
}

OUT="$TEST_DIR/out"
ERR="$TEST_DIR/err"
run_monitor() {
    set +e
    PATH="$BIN:$PATH" FIX="$FIX" MONITOR_GH_PR_STATE_ROOT="$TEST_DIR/state" \
        bash "$SCRIPT" owner/repo 42 --reviewer mihai "$@" > "$OUT" 2> "$ERR"
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

pr_meta OPEN sha-4
echo '{"message":"Not Found","status":"404"}' > "$FIX/compare"
touch "$FIX/compare_fails"
run_monitor
assert "a failed compare falls back to the force-push note" reported "force-push or rebase: sha-3 → sha-4"
assert_not "a failed compare does not print the error body" reported "Not Found"

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

# ── Comma-containing team names must not fool membership checks ─────────────

reset_state
run_monitor
printf '{"state":"OPEN","headRefOid":"sha-1","reviewRequests":[{"name":"Gates: x,mihai"}]}\n' > "$FIX/pr_meta"
run_monitor
assert "comma-containing team name is reported as a set change" reported "Review requests changed"
assert_not "comma-containing team name does not fake a re-review flag" reported "Re-review requested from mihai"

# ── Comments and reviews ──────────────────────────────────────────────────────

reset_state
printf '101\n' > "$FIX/regular"
run_monitor
assert "existing comments are not re-reported" [ "$STATUS" -eq 1 ]

printf '101\n102\n' > "$FIX/regular"
echo 7 > "$FIX/review"
pr_reviews "9 other COMMENTED sha-1"
run_monitor
assert "new PR comment is reported" reported "1 new PR comment(s)"
assert "new inline review comment is reported" reported "1 new inline review comment(s)"
assert "new PR review is reported" reported "1 new PR review(s)"

run_monitor
assert "handled comments are not re-reported" [ "$STATUS" -eq 1 ]

# ── Dismissed reviews ─────────────────────────────────────────────────────────

reset_state
pr_reviews "9 mihai APPROVED sha-1"
run_monitor
pr_reviews "9 mihai DISMISSED sha-1"
run_monitor
assert "dismissal of the watched reviewer's approval is reported" reported "mihai's APPROVED review 9 was dismissed"
assert "dismissal exits actionable" [ "$STATUS" -eq 0 ]

run_monitor
assert "a handled dismissal is not re-reported" [ "$STATUS" -eq 1 ]

reset_state
pr_reviews "9 mihai APPROVED sha-1"
run_monitor
echo '{"message":"Server Error"}' > "$FIX/pr_reviews"
run_monitor
assert "an API error body on the reviews call leaves the watcher idle" [ "$STATUS" -eq 1 ]
pr_reviews "9 mihai DISMISSED sha-1"
run_monitor
assert "a dismissal after an API error is still reported" reported "mihai's APPROVED review 9 was dismissed"

reset_state
pr_reviews "9 other APPROVED sha-1"
run_monitor
pr_reviews "9 other DISMISSED sha-1"
run_monitor
assert "another reviewer's dismissal is not reported" [ "$STATUS" -eq 1 ]

# ── Re-review mode ────────────────────────────────────────────────────────────

reset_state
pr_reviews "9 mihai CHANGES_REQUESTED sha-1"
run_monitor
pr_meta OPEN sha-2
run_monitor
assert_not "without --rereview there is no re-review block" reported "Re-review"

reset_state
pr_reviews "9 mihai CHANGES_REQUESTED sha-1"
threads "false false src/a.ts 10 2 mihai minor: untested ?? []" \
        "true true src/b.ts 20 1 mihai nit: rename this" \
        "false false src/c.ts 30 1 other unrelated thread" \
        "false false src/d.ts 40 1 mihai $(printf 'x%.0s' {1..150})"
run_monitor --rereview confirm
assert "re-review baseline is idle" [ "$STATUS" -eq 1 ]
pr_meta OPEN sha-2
run_monitor --rereview confirm
assert "re-review block names the mode" reported "## Re-review (mode: confirm)"
assert "re-review block shows the last verdict and its commit" reported "Last review by mihai: CHANGES_REQUESTED on sha-1 (review 9)"
assert "re-review range runs from the reviewed commit to the new head" reported "Re-review range: sha-1...sha-2"
assert "an open reviewer thread is listed with its location and reply count" reported "open .*src/a.ts:10 .*(2 comments) minor: untested ?? \[\]"
assert "a resolved outdated thread is listed at its original line" reported "resolved, outdated .*src/b.ts:20 .*(1 comment) nit: rename this"
assert_not "threads started by someone else are not listed" reported "unrelated thread"
assert "a long thread opener is cut short" reported "src/d.ts:40 .*(1 comment) $(printf 'x%.0s' {1..100})…$"
assert "confirm mode says nothing gets posted without a go" reported "Post nothing without mihai's explicit go"

reset_state
pr_reviews "9 mihai APPROVED sha-1"
run_monitor --rereview auto-approve
pr_reviews "9 mihai DISMISSED sha-1"
pr_meta OPEN sha-2
run_monitor --rereview auto-approve
assert "auto-approve mode is named" reported "## Re-review (mode: auto-approve)"
assert "a dismissed last review shows what it was" reported "Last review by mihai: DISMISSED (was APPROVED) on sha-1"
assert "auto-approve mode limits itself to the approval gate" reported "Only an empty-body approval may go up without asking"

reset_state
run_monitor --rereview confirm
pr_meta OPEN sha-2
run_monitor --rereview confirm
assert "no earlier review means the whole PR needs review" reported "No review by mihai yet: review the whole PR"

reset_state
pr_reviews "9 mihai CHANGES_REQUESTED sha-1"
run_monitor --rereview confirm
printf '101\n' > "$FIX/regular"
run_monitor --rereview confirm
assert "a comment-only wake has an empty re-review range" reported "Re-review range: none (head sha-1 is the reviewed commit)"

reset_state
run_monitor --rereview always
assert "an unknown re-review mode is rejected with usage" grep -q "Unknown --rereview mode: always" "$ERR"
assert_not "an unknown re-review mode does not start watching" grep -q "Watching" "$ERR"

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo "Passed: $PASS  Failed: $FAIL"
[ "$FAIL" -eq 0 ]
