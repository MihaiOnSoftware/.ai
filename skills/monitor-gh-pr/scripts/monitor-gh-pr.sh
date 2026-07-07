#!/usr/bin/env bash
set -euo pipefail

# monitor-gh-pr.sh
# Poll a GitHub PR for CI status changes and new comments.
# Exits 0 with a summary on the first actionable event.
#
# Usage: monitor-gh-pr.sh <REPO> <PR_NUMBER> [--interval <seconds>]

usage() {
  cat >&2 <<'EOF'
Usage: monitor-gh-pr.sh <REPO> <PR_NUMBER> [--interval <seconds>]

Monitor a GitHub PR for CI failures, CI success, and new comments.

Arguments:
  REPO        Repository in owner/repo format (e.g. MaintainX/maintainx)
  PR_NUMBER   Pull request number
  --interval  Polling interval in seconds (default: 60)

Exits 0 with a human-readable summary when something actionable occurs:
  • A CI check fails
  • All CI checks pass
  • New PR comments appear
  • New inline review comments appear

State is stored in /tmp/monitor-gh-pr-<slug>-<pr>/. Delete that directory to
reset the comment baseline (so existing comments are re-reported on next run).
EOF
  exit 1
}

# ── Argument parsing ───────────────────────────────────────────────────────────
REPO=""
PR_NUMBER=""
INTERVAL=60

while [[ $# -gt 0 ]]; do
  case "$1" in
    --interval)
      [[ -z "${2:-}" ]] && { echo "--interval requires a value" >&2; usage; }
      INTERVAL="$2"
      shift 2
      ;;
    -h|--help) usage ;;
    -*)
      echo "Unknown option: $1" >&2
      usage
      ;;
    *)
      if   [[ -z "$REPO"      ]]; then REPO="$1"
      elif [[ -z "$PR_NUMBER" ]]; then PR_NUMBER="$1"
      else usage
      fi
      shift
      ;;
  esac
done

[[ -z "$REPO" || -z "$PR_NUMBER" ]] && usage

# ── State directory ────────────────────────────────────────────────────────────
SLUG=$(printf '%s' "$REPO" | tr '/' '-')
STATE_DIR="/tmp/monitor-gh-pr-${SLUG}-${PR_NUMBER}"
mkdir -p "$STATE_DIR"

REGULAR_IDS_FILE="$STATE_DIR/regular_ids"
REVIEW_IDS_FILE="$STATE_DIR/review_ids"
PR_REVIEWS_IDS_FILE="$STATE_DIR/pr_review_ids"
INITIALIZED_FILE="$STATE_DIR/initialized"

CURRENT_REGULAR_TMP=$(mktemp)
CURRENT_REVIEW_TMP=$(mktemp)
CURRENT_PR_REVIEWS_TMP=$(mktemp)
trap 'rm -f "$CURRENT_REGULAR_TMP" "$CURRENT_REVIEW_TMP" "$CURRENT_PR_REVIEWS_TMP"' EXIT

# ── Helpers ────────────────────────────────────────────────────────────────────
now() { date '+%H:%M:%S'; }

fetch_regular_ids() {
  gh api "/repos/${REPO}/issues/${PR_NUMBER}/comments" --paginate \
    --jq '.[].id' 2>/dev/null || true
}

fetch_review_ids() {
  gh api "/repos/${REPO}/pulls/${PR_NUMBER}/comments" --paginate \
    --jq '.[].id' 2>/dev/null || true
}

fetch_pr_review_ids() {
  gh api "/repos/${REPO}/pulls/${PR_NUMBER}/reviews" --paginate \
    --jq '[.[] | select(.body != "")] | .[].id' 2>/dev/null || true
}

# IDs present in $2 but absent from $1 (both are file paths).
new_ids() {
  awk 'NR==FNR { seen[$1]=1; next } !seen[$1] { print }' "$1" "$2"
}

# Count non-empty lines in a variable; returns 0 for empty string.
count_lines() {
  local s="$1"
  if [[ -z "$s" ]]; then echo 0; return; fi
  echo "$s" | wc -l | tr -d ' '
}

# ── Baseline (first run) ───────────────────────────────────────────────────────
if [[ ! -f "$INITIALIZED_FILE" ]]; then
  echo "[$(now)] Initializing baseline for ${REPO}#${PR_NUMBER}..." >&2
  fetch_regular_ids    > "$REGULAR_IDS_FILE"
  fetch_review_ids     > "$REVIEW_IDS_FILE"
  fetch_pr_review_ids  > "$PR_REVIEWS_IDS_FILE"
  touch "$INITIALIZED_FILE"
  R=$(wc -l < "$REGULAR_IDS_FILE"    | tr -d ' ')
  V=$(wc -l < "$REVIEW_IDS_FILE"     | tr -d ' ')
  P=$(wc -l < "$PR_REVIEWS_IDS_FILE" | tr -d ' ')
  echo "[$(now)] Baseline: ${R} regular comment(s), ${V} inline review comment(s), ${P} PR review(s)." >&2
fi

echo "[$(now)] Watching ${REPO}#${PR_NUMBER} every ${INTERVAL}s. Ctrl+C to stop." >&2

# ── Poll loop ──────────────────────────────────────────────────────────────────
while true; do
  echo "[$(now)] Polling ${REPO}#${PR_NUMBER}..." >&2

  ACTIONABLE=false
  SUMMARY=()

  # CI checks
  CI_JSON=$(gh pr checks "$PR_NUMBER" --repo "$REPO" --json name,state,bucket 2>/dev/null || echo "[]")
  TOTAL=$(echo "$CI_JSON" | jq 'length')

  if [[ "$TOTAL" -gt 0 ]]; then
    FAILED=$(echo "$CI_JSON" | jq '[.[] | select(.bucket == "fail")] | length')
    # Exclude state=WAITING (manual approval gates) — they never self-resolve
    PENDING=$(echo "$CI_JSON" | jq '[.[] | select(
      .bucket != "pass" and .bucket != "fail" and
      .bucket != "skipping" and .bucket != "cancel" and
      .state != "WAITING"
    )] | length')
    WAITING=$(echo "$CI_JSON" | jq '[.[] | select(.state == "WAITING")] | length')

    if [[ "$FAILED" -gt 0 ]]; then
      SUMMARY+=("## CI Failing — ${FAILED} of ${TOTAL} checks failed")
      while IFS= read -r name; do
        SUMMARY+=("  ❌  ${name}")
      done < <(echo "$CI_JSON" | jq -r '.[] | select(.bucket == "fail") | .name')
      SUMMARY+=("")
      ACTIONABLE=true
    elif [[ "$PENDING" -eq 0 ]]; then
      PASSED=$(echo "$CI_JSON" | jq '[.[] | select(.bucket == "pass")] | length')
      if [[ "$WAITING" -gt 0 ]]; then
        SUMMARY+=("## CI Passed — ${PASSED} of ${TOTAL} checks ✅ (${WAITING} manual gate(s) awaiting approval)")
      else
        SUMMARY+=("## CI Passed — ${PASSED} of ${TOTAL} checks ✅")
      fi
      SUMMARY+=("")
      ACTIONABLE=true
    fi
  fi

  # Regular PR comments
  fetch_regular_ids > "$CURRENT_REGULAR_TMP"
  NEW_REGULAR=$(new_ids "$REGULAR_IDS_FILE" "$CURRENT_REGULAR_TMP")

  if [[ -n "$NEW_REGULAR" ]]; then
    N=$(count_lines "$NEW_REGULAR")
    SUMMARY+=("## ${N} new PR comment(s) on ${REPO}#${PR_NUMBER}")
    SUMMARY+=("")
    cp "$CURRENT_REGULAR_TMP" "$REGULAR_IDS_FILE"
    ACTIONABLE=true
  fi

  # Inline review comments
  fetch_review_ids > "$CURRENT_REVIEW_TMP"
  NEW_REVIEW=$(new_ids "$REVIEW_IDS_FILE" "$CURRENT_REVIEW_TMP")

  if [[ -n "$NEW_REVIEW" ]]; then
    N=$(count_lines "$NEW_REVIEW")
    SUMMARY+=("## ${N} new inline review comment(s) on ${REPO}#${PR_NUMBER}")
    SUMMARY+=("")
    cp "$CURRENT_REVIEW_TMP" "$REVIEW_IDS_FILE"
    ACTIONABLE=true
  fi

  # PR reviews (top-level review submissions, e.g. bugbot, approve/request-changes)
  fetch_pr_review_ids > "$CURRENT_PR_REVIEWS_TMP"
  NEW_PR_REVIEWS=$(new_ids "$PR_REVIEWS_IDS_FILE" "$CURRENT_PR_REVIEWS_TMP")

  if [[ -n "$NEW_PR_REVIEWS" ]]; then
    N=$(count_lines "$NEW_PR_REVIEWS")
    SUMMARY+=("## ${N} new PR review(s) on ${REPO}#${PR_NUMBER}")
    SUMMARY+=("")
    cp "$CURRENT_PR_REVIEWS_TMP" "$PR_REVIEWS_IDS_FILE"
    ACTIONABLE=true
  fi

  if $ACTIONABLE; then
    printf '\n=== Actionable: %s#%s at %s ===\n' "$REPO" "$PR_NUMBER" "$(now)"
    printf '%s\n' "${SUMMARY[@]}"
    exit 0
  fi

  echo "[$(now)] Nothing new — sleeping ${INTERVAL}s." >&2
  sleep "$INTERVAL"
done
