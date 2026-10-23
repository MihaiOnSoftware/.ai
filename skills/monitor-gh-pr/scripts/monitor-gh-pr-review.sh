#!/usr/bin/env bash
set -euo pipefail

# monitor-gh-pr-review.sh
# Reviewer-side watcher: poll a PR you are REVIEWING (not authoring) for events
# that need the reviewer's attention. Exits 0 with a summary on the first one.
#
# Usage: monitor-gh-pr-review.sh <REPO> <PR_NUMBER> [--interval <seconds>] [--reviewer <login>]

usage() {
  cat >&2 <<'EOF'
Usage: monitor-gh-pr-review.sh <REPO> <PR_NUMBER> [--interval <seconds>] [--reviewer <login>]

Monitor a PR you are REVIEWING for events that need reviewer attention.
For a PR you authored, use monitor-gh-pr.sh instead — it watches CI.

Arguments:
  REPO        Repository in owner/repo format (e.g. MaintainX/maintainx)
  PR_NUMBER   Pull request number
  --interval  Polling interval in seconds (default: 300)
  --reviewer  Login whose re-review requests get flagged (default: the gh-authenticated user)

Exits 0 with a human-readable summary when something actionable occurs:
  • The PR merges or closes
  • New commits are pushed (head changes; lists the new commit subjects)
  • The requested-reviewers set changes (flags when <reviewer> is newly requested)
  • New PR comments, inline review comments, or PR reviews appear

State is stored in $MONITOR_GH_PR_STATE_ROOT/monitor-gh-pr-review-<slug>-<pr>/
(default root: /tmp). Delete that directory to reset the baseline (so existing
comments are re-reported on next run).
EOF
  exit 1
}

# ── Argument parsing ───────────────────────────────────────────────────────────
REPO=""
PR_NUMBER=""
INTERVAL=300
REVIEWER=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --interval)
      [[ -z "${2:-}" ]] && { echo "--interval requires a value" >&2; usage; }
      INTERVAL="$2"
      shift 2
      ;;
    --reviewer)
      [[ -z "${2:-}" ]] && { echo "--reviewer requires a value" >&2; usage; }
      REVIEWER="$2"
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

if [[ -z "$REVIEWER" ]]; then
  REVIEWER=$(gh api user --jq '.login' 2>/dev/null || true)
fi

# ── State directory ────────────────────────────────────────────────────────────
SLUG=$(printf '%s' "$REPO" | tr '/' '-')
STATE_DIR="${MONITOR_GH_PR_STATE_ROOT:-/tmp}/monitor-gh-pr-review-${SLUG}-${PR_NUMBER}"
mkdir -p "$STATE_DIR"

REGULAR_IDS_FILE="$STATE_DIR/regular_ids"
REVIEW_IDS_FILE="$STATE_DIR/review_ids"
PR_REVIEWS_IDS_FILE="$STATE_DIR/pr_review_ids"
HEAD_SHA_FILE="$STATE_DIR/head_sha"
REQUESTED_FILE="$STATE_DIR/requested_reviewers"
INITIALIZED_FILE="$STATE_DIR/initialized"

CURRENT_REGULAR_TMP=$(mktemp)
CURRENT_REVIEW_TMP=$(mktemp)
CURRENT_PR_REVIEWS_TMP=$(mktemp)
trap 'rm -f "$CURRENT_REGULAR_TMP" "$CURRENT_REVIEW_TMP" "$CURRENT_PR_REVIEWS_TMP"' EXIT

# ── Helpers ────────────────────────────────────────────────────────────────────
now() { date '+%H:%M:%S'; }

fetch_pr_meta() {
  gh pr view "$PR_NUMBER" --repo "$REPO" --json state,headRefOid,reviewRequests \
    2>/dev/null || echo '{}'
}

meta_state()     { echo "$1" | jq -r '.state // empty'; }
meta_head()      { echo "$1" | jq -r '.headRefOid // empty'; }
meta_requested() { echo "$1" | jq -r '[.reviewRequests[]? | .login // .name] | sort | join(",")'; }

fetch_regular_ids() {
  gh api "/repos/${REPO}/issues/${PR_NUMBER}/comments" --paginate \
    --jq '.[].id' 2>/dev/null || true
}

fetch_review_ids() {
  gh api "/repos/${REPO}/pulls/${PR_NUMBER}/comments" --paginate \
    --jq '.[].id' 2>/dev/null || true
}

# No empty-body filter here (unlike monitor-gh-pr.sh): a bodyless APPROVED or
# CHANGES_REQUESTED verdict is exactly what a reviewer is waiting on.
fetch_pr_review_ids() {
  gh api "/repos/${REPO}/pulls/${PR_NUMBER}/reviews" --paginate \
    --jq '.[].id' 2>/dev/null || true
}

# One line per commit between two heads; falls back when compare fails
# (e.g. force-push or rebase makes the old head unreachable).
list_new_commits() {
  local old="$1" new="$2" commits
  commits=$(gh api "/repos/${REPO}/compare/${old}...${new}" \
    --jq '.commits[] | "  •  " + .sha[0:11] + " " + (.commit.message | split("\n")[0])' \
    2>/dev/null || true)
  if [[ -n "$commits" ]]; then
    echo "$commits"
  else
    echo "  •  (force-push or rebase: ${old:0:11} → ${new:0:11})"
  fi
}

# IDs present in $2 but absent from $1 (both are file paths).
# FILENAME==ARGV[1] (not NR==FNR) so an empty baseline file still reports new IDs.
new_ids() {
  awk 'FILENAME==ARGV[1] { seen[$1]=1; next } !seen[$1] { print }' "$1" "$2"
}

# Count non-empty lines in a variable; returns 0 for empty string.
count_lines() {
  local s="$1"
  if [[ -z "$s" ]]; then echo 0; return; fi
  echo "$s" | wc -l | tr -d ' '
}

csv_contains() { [[ ",$1," == *",$2,"* ]]; }

# ── Baseline (first run) ───────────────────────────────────────────────────────
if [[ ! -f "$INITIALIZED_FILE" ]]; then
  echo "[$(now)] Initializing baseline for ${REPO}#${PR_NUMBER}..." >&2
  META=$(fetch_pr_meta)
  meta_head "$META"      > "$HEAD_SHA_FILE"
  meta_requested "$META" > "$REQUESTED_FILE"
  fetch_regular_ids      > "$REGULAR_IDS_FILE"
  fetch_review_ids       > "$REVIEW_IDS_FILE"
  fetch_pr_review_ids    > "$PR_REVIEWS_IDS_FILE"
  touch "$INITIALIZED_FILE"
  R=$(wc -l < "$REGULAR_IDS_FILE"    | tr -d ' ')
  V=$(wc -l < "$REVIEW_IDS_FILE"     | tr -d ' ')
  P=$(wc -l < "$PR_REVIEWS_IDS_FILE" | tr -d ' ')
  echo "[$(now)] Baseline: head $(cut -c1-11 "$HEAD_SHA_FILE"), requested [$(cat "$REQUESTED_FILE")], ${R} regular comment(s), ${V} inline review comment(s), ${P} PR review(s)." >&2
fi

echo "[$(now)] Watching ${REPO}#${PR_NUMBER} every ${INTERVAL}s (reviewer: ${REVIEWER:-none}). Ctrl+C to stop." >&2

# ── Poll loop ──────────────────────────────────────────────────────────────────
while true; do
  echo "[$(now)] Polling ${REPO}#${PR_NUMBER}..." >&2

  ACTIONABLE=false
  SUMMARY=()

  META=$(fetch_pr_meta)
  STATE=$(meta_state "$META")

  # Merge/close ends the watch — nothing after it needs reviewer attention.
  if [[ -n "$STATE" && "$STATE" != "OPEN" ]]; then
    printf '\n=== Actionable: %s#%s at %s ===\n' "$REPO" "$PR_NUMBER" "$(now)"
    printf '## PR is %s\n' "$STATE"
    exit 0
  fi

  # New commits
  NEW_HEAD=$(meta_head "$META")
  OLD_HEAD=$(cat "$HEAD_SHA_FILE" 2>/dev/null || true)
  if [[ -n "$NEW_HEAD" && "$NEW_HEAD" != "$OLD_HEAD" ]]; then
    SUMMARY+=("## New commit(s) — head ${OLD_HEAD:0:11} → ${NEW_HEAD:0:11}")
    while IFS= read -r line; do
      SUMMARY+=("$line")
    done < <(list_new_commits "$OLD_HEAD" "$NEW_HEAD")
    SUMMARY+=("")
    echo "$NEW_HEAD" > "$HEAD_SHA_FILE"
    ACTIONABLE=true
  fi

  # Requested-reviewers changes
  NEW_REQUESTED=$(meta_requested "$META")
  OLD_REQUESTED=$(cat "$REQUESTED_FILE" 2>/dev/null || true)
  if [[ "$NEW_REQUESTED" != "$OLD_REQUESTED" ]]; then
    SUMMARY+=("## Review requests changed — was [${OLD_REQUESTED:-none}], now [${NEW_REQUESTED:-none}]")
    if [[ -n "$REVIEWER" ]] && csv_contains "$NEW_REQUESTED" "$REVIEWER" && ! csv_contains "$OLD_REQUESTED" "$REVIEWER"; then
      SUMMARY+=("  🔔  Re-review requested from ${REVIEWER}")
    fi
    SUMMARY+=("")
    echo "$NEW_REQUESTED" > "$REQUESTED_FILE"
    ACTIONABLE=true
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

  # PR reviews (approve / request-changes / comment verdicts)
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
