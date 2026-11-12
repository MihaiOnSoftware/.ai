#!/usr/bin/env bash
set -euo pipefail

# monitor-gh-pr-review.sh
# Reviewer-side watcher: poll a PR you are REVIEWING (not authoring) for events
# that need the reviewer's attention. Exits 0 with a summary on the first one.
#
# Usage: monitor-gh-pr-review.sh <REPO> <PR_NUMBER> [--interval <seconds>] [--reviewer <login>] [--rereview <mode>]

usage() {
  cat >&2 <<'EOF'
Usage: monitor-gh-pr-review.sh <REPO> <PR_NUMBER> [--interval <seconds>] [--reviewer <login>] [--rereview <mode>]

Monitor a PR you are REVIEWING for events that need reviewer attention.
For a PR you authored, use monitor-gh-pr.sh instead — it watches CI.

Arguments:
  REPO        Repository in owner/repo format (e.g. MaintainX/maintainx)
  PR_NUMBER   Pull request number
  --interval  Polling interval in seconds (default: 300)
  --reviewer  Login whose re-review requests and dismissed reviews get flagged
              (default: the gh-authenticated user)
  --rereview  Opt-in re-review mode: confirm | auto-approve. Adds a re-review
              block (last verdict, range to re-review, the reviewer's threads)
              to every report. The script itself never posts anything.

Exits 0 with a human-readable summary when something actionable occurs:
  • The PR merges or closes
  • New commits are pushed (head changes; lists the new commit subjects)
  • The requested-reviewers set changes (flags when <reviewer> is newly requested)
  • A review by <reviewer> is dismissed
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
REREVIEW=""

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
    --rereview)
      [[ -z "${2:-}" ]] && { echo "--rereview requires a mode" >&2; usage; }
      case "$2" in
        confirm|auto-approve) REREVIEW="$2" ;;
        *) echo "Unknown --rereview mode: $2 (use confirm or auto-approve)" >&2; usage ;;
      esac
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

if [[ -n "$REREVIEW" && -z "$REVIEWER" ]]; then
  echo "--rereview needs a reviewer: pass --reviewer <login> or authenticate gh" >&2
  exit 1
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
REVIEWER_STATES_FILE="$STATE_DIR/reviewer_review_states"
DISMISSED_FROM_FILE="$STATE_DIR/dismissed_from"
INITIALIZED_FILE="$STATE_DIR/initialized"

CURRENT_REGULAR_TMP=$(mktemp)
CURRENT_REVIEW_TMP=$(mktemp)
CURRENT_PR_REVIEWS_TMP=$(mktemp)
CURRENT_STATES_TMP=$(mktemp)
trap 'rm -f "$CURRENT_REGULAR_TMP" "$CURRENT_REVIEW_TMP" "$CURRENT_PR_REVIEWS_TMP" "$CURRENT_STATES_TMP"' EXIT

# ── Helpers ────────────────────────────────────────────────────────────────────
now() { date '+%H:%M:%S'; }

fetch_pr_meta() {
  gh pr view "$PR_NUMBER" --repo "$REPO" --json state,headRefOid,reviewRequests \
    2>/dev/null || echo '{}'
}

meta_state()     { echo "$1" | jq -r '.state // empty'; }
meta_head()      { echo "$1" | jq -r '.headRefOid // empty'; }
# One reviewer per line, sorted. Line-based (not CSV) so team display names
# containing commas cannot corrupt comparison or membership checks.
meta_requested() { echo "$1" | jq -r '.reviewRequests[]? | .login // .name' | sort; }

fetch_regular_ids() {
  gh api "/repos/${REPO}/issues/${PR_NUMBER}/comments" --paginate \
    --jq '.[].id' 2>/dev/null || true
}

fetch_review_ids() {
  gh api "/repos/${REPO}/pulls/${PR_NUMBER}/comments" --paginate \
    --jq '.[].id' 2>/dev/null || true
}

# Raw JSON (one array per page), filtered locally so every view below reads
# the same snapshot. Empty when the call fails: gh prints an HTTP error body
# (an object, not an array) on stdout.
fetch_pr_reviews() {
  gh api "/repos/${REPO}/pulls/${PR_NUMBER}/reviews" --paginate 2>/dev/null \
    | jq -c 'select(type == "array")' 2>/dev/null || true
}

# No empty-body filter here (unlike monitor-gh-pr.sh): a bodyless APPROVED or
# CHANGES_REQUESTED verdict is exactly what a reviewer is waiting on.
review_ids() { echo "$1" | jq -r '.[].id'; }

# "<id> <state>" per review by the watched reviewer. A dismissal keeps the id
# and only changes the state, so the id list alone never notices it.
reviewer_states() {
  echo "$1" | jq -r --arg r "$REVIEWER" '.[] | select(.user.login == $r) | "\(.id) \(.state)"'
}

# Ids whose state turned DISMISSED since $1, as "<id> <previous state>" (both file paths).
newly_dismissed() {
  awk 'FILENAME==ARGV[1] { was[$1]=$2; next } $2=="DISMISSED" && ($1 in was) && was[$1]!="DISMISSED" { print $1, was[$1] }' "$1" "$2"
}

# One line per commit between two heads; falls back when compare fails
# (e.g. force-push or rebase makes the old head unreachable). On failure gh
# prints the HTTP error body on stdout, so the exit status decides, not output.
list_new_commits() {
  local old="$1" new="$2" commits
  if commits=$(gh api "/repos/${REPO}/compare/${old}...${new}" \
    --jq '.commits[] | "  •  " + .sha[0:11] + " " + (.commit.message | split("\n")[0])' \
    2>/dev/null) && [[ -n "$commits" ]]; then
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

# Exact-line membership in a newline-separated list.
list_contains() { grep -Fxq "$2" <<< "$1"; }

# Comma-joined display form of a newline-separated list; "none" when empty.
list_display() {
  if [[ -z "$1" ]]; then echo "none"; else printf '%s' "$1" | paste -sd, -; fi
}

# ── Re-review block ────────────────────────────────────────────────────────────

# shellcheck disable=SC2016  # $owner/$name/$number are GraphQL variables, not shell
fetch_reviewer_threads() {
  gh api graphql -f owner="${REPO%%/*}" -f name="${REPO##*/}" -F number="$PR_NUMBER" -f query='
    query($owner: String!, $name: String!, $number: Int!) {
      repository(owner: $owner, name: $name) {
        pullRequest(number: $number) {
          reviewThreads(first: 100) {
            nodes {
              isResolved isOutdated path line originalLine
              comments(first: 1) { totalCount nodes { author { login } body } }
            }
          }
        }
      }
    }' 2>/dev/null | jq -r --arg r "$REVIEWER" '
    .data.repository.pullRequest.reviewThreads.nodes[]?
    | select(.comments.nodes[0].author.login == $r)
    | "  •  " + (if .isResolved then "resolved" else "open" end)
      + (if .isOutdated then ", outdated" else "" end)
      + "  " + .path + ":" + ((.line // .originalLine) | tostring)
      + "  (" + (.comments.totalCount | tostring) + " comment" + (if .comments.totalCount == 1 then "" else "s" end) + ") "
      + (.comments.nodes[0].body | split("\n")[0] | if length > 100 then .[0:100] + "…" else . end)' 2>/dev/null || true
}

# Facts the re-review steps start from; printed only in --rereview mode.
rereview_block() {
  local reviews="$1" head="$2" last state commit id was threads
  last=$(echo "$reviews" | jq -c --arg r "$REVIEWER" \
    '[.[] | select(.user.login == $r and .state != "PENDING")] | last // empty' 2>/dev/null | tail -n 1)

  echo "## Re-review (mode: ${REREVIEW})"
  if [[ -z "$last" ]]; then
    echo "  No review by ${REVIEWER} yet: review the whole PR."
  else
    state=$(echo "$last" | jq -r '.state')
    commit=$(echo "$last" | jq -r '.commit_id // empty')
    id=$(echo "$last" | jq -r '.id')
    was=""
    if [[ -f "$DISMISSED_FROM_FILE" ]]; then
      was=$(awk -v id="$id" '$1==id { print $2 }' "$DISMISSED_FROM_FILE" | tail -n 1)
    fi
    if [[ -n "$was" ]]; then state="${state} (was ${was})"; fi
    echo "  Last review by ${REVIEWER}: ${state} on ${commit:0:11} (review ${id})"
    if [[ "$commit" == "$head" ]]; then
      echo "  Re-review range: none (head ${head:0:11} is the reviewed commit)"
    else
      echo "  Re-review range: ${commit}...${head}"
    fi
  fi

  threads=$(fetch_reviewer_threads)
  echo "  Threads started by ${REVIEWER} (first 100):"
  if [[ -n "$threads" ]]; then echo "$threads"; else echo "  •  none"; fi

  if [[ "$REREVIEW" == "auto-approve" ]]; then
    echo "  Next: re-review per monitor-gh-pr references/rereview.md. Only an empty-body approval may go up without asking, and only on a clean gate; everything else needs ${REVIEWER}'s explicit go."
  else
    echo "  Next: re-review per monitor-gh-pr references/rereview.md. Post nothing without ${REVIEWER}'s explicit go."
  fi
}

# ── Baseline (first run) ───────────────────────────────────────────────────────
if [[ ! -f "$INITIALIZED_FILE" ]]; then
  echo "[$(now)] Initializing baseline for ${REPO}#${PR_NUMBER}..." >&2
  META=$(fetch_pr_meta)
  meta_head "$META"      > "$HEAD_SHA_FILE"
  meta_requested "$META" > "$REQUESTED_FILE"
  fetch_regular_ids      > "$REGULAR_IDS_FILE"
  fetch_review_ids       > "$REVIEW_IDS_FILE"
  REVIEWS=$(fetch_pr_reviews)
  review_ids "$REVIEWS"      > "$PR_REVIEWS_IDS_FILE"
  reviewer_states "$REVIEWS" > "$REVIEWER_STATES_FILE"
  touch "$INITIALIZED_FILE"
  R=$(wc -l < "$REGULAR_IDS_FILE"    | tr -d ' ')
  V=$(wc -l < "$REVIEW_IDS_FILE"     | tr -d ' ')
  P=$(wc -l < "$PR_REVIEWS_IDS_FILE" | tr -d ' ')
  echo "[$(now)] Baseline: head $(cut -c1-11 "$HEAD_SHA_FILE"), requested [$(list_display "$(cat "$REQUESTED_FILE")")], ${R} regular comment(s), ${V} inline review comment(s), ${P} PR review(s)." >&2
fi

echo "[$(now)] Watching ${REPO}#${PR_NUMBER} every ${INTERVAL}s (reviewer: ${REVIEWER:-none}, re-review: ${REREVIEW:-off}). Ctrl+C to stop." >&2

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
    SUMMARY+=("## Review requests changed — was [$(list_display "$OLD_REQUESTED")], now [$(list_display "$NEW_REQUESTED")]")
    if [[ -n "$REVIEWER" ]] && list_contains "$NEW_REQUESTED" "$REVIEWER" && ! list_contains "$OLD_REQUESTED" "$REVIEWER"; then
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
  REVIEWS=$(fetch_pr_reviews)
  review_ids "$REVIEWS" > "$CURRENT_PR_REVIEWS_TMP"
  NEW_PR_REVIEWS=$(new_ids "$PR_REVIEWS_IDS_FILE" "$CURRENT_PR_REVIEWS_TMP")

  if [[ -n "$NEW_PR_REVIEWS" ]]; then
    N=$(count_lines "$NEW_PR_REVIEWS")
    SUMMARY+=("## ${N} new PR review(s) on ${REPO}#${PR_NUMBER}")
    SUMMARY+=("")
    cp "$CURRENT_PR_REVIEWS_TMP" "$PR_REVIEWS_IDS_FILE"
    ACTIONABLE=true
  fi

  # Dismissals of the watched reviewer's own reviews. Skipped when the fetch
  # failed, so a blip cannot wipe the states a later dismissal is compared to.
  if [[ -n "$REVIEWS" ]]; then
    reviewer_states "$REVIEWS" > "$CURRENT_STATES_TMP"
    DISMISSED=$(newly_dismissed "$REVIEWER_STATES_FILE" "$CURRENT_STATES_TMP")

    if [[ -n "$DISMISSED" ]]; then
      while read -r review_id previous; do
        SUMMARY+=("## Review dismissed — ${REVIEWER}'s ${previous} review ${review_id} was dismissed")
      done <<< "$DISMISSED"
      SUMMARY+=("")
      echo "$DISMISSED" >> "$DISMISSED_FROM_FILE"
      ACTIONABLE=true
    fi
    cp "$CURRENT_STATES_TMP" "$REVIEWER_STATES_FILE"
  fi

  if $ACTIONABLE; then
    printf '\n=== Actionable: %s#%s at %s ===\n' "$REPO" "$PR_NUMBER" "$(now)"
    printf '%s\n' "${SUMMARY[@]}"
    [[ -n "$REREVIEW" ]] && rereview_block "$REVIEWS" "$NEW_HEAD"
    exit 0
  fi

  echo "[$(now)] Nothing new — sleeping ${INTERVAL}s." >&2
  sleep "$INTERVAL"
done
