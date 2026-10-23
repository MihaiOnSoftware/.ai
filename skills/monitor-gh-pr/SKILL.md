---
name: monitor-gh-pr
description: Monitor a GitHub PR for actionable events. Two scripts, picked by role — author mode (monitor-gh-pr.sh) watches CI results and new comments after you push; reviewer mode (monitor-gh-pr-review.sh) watches a PR you are reviewing for merge/close, new commits, re-review requests, and new comments. Trigger phrases include "watch my PR", "monitor PR #N", "notify me when CI is done", "background CI watch", "let me know if there are new comments", "watch this PR for re-requests", "tell me when they push changes".
license: MIT
metadata:
  category: github
---

# Monitor GitHub PR

Two polling scripts, picked by your role on the PR. Both run until something actionable happens, print a summary to stdout, and exit 0.

| Your role | Script | Watches |
|---|---|---|
| **Author** — you wrote/pushed the PR | `./scripts/monitor-gh-pr.sh` | CI failures, CI success, new comments |
| **Reviewer** — you are reviewing someone else's PR | `./scripts/monitor-gh-pr-review.sh` | merge/close, new commits (with subjects), re-review requests, new comments and reviews |

Picking wrong wastes the watch: the author script never notices pushed commits or your re-review being requested; the reviewer script never watches CI.

## When to Use

**Author mode**: after pushing to a branch when you want to keep working on something else while CI runs.

**Reviewer mode**: after submitting review comments on someone else's PR, when you want to be told the author responded — pushed fix commits, replied, re-requested your review — or the PR merged/closed. Typical loop: review → start the watcher → on wake, assess the delta against your review → re-arm until merged.

Either way the script handles the polling; your job is to run it in the background using whatever mechanism your harness provides and surface its output when it exits.

## Inputs

| Input | Script | Description | Example |
|-------|--------|-------------|---------|
| `REPO` | both | `owner/repo` | `MaintainX/maintainx` |
| `PR_NUMBER` | both | PR number | `38873` |
| `--interval N` | both | Poll interval in seconds (author default: 60; reviewer default: 300 — review turnarounds are slower than CI) | `--interval 120` |
| `--reviewer LOGIN` | reviewer only | Login whose re-review requests get flagged prominently (default: the gh-authenticated user) | `--reviewer MihaiOnSoftware` |

## Step 1 — Resolve REPO and PR_NUMBER

**From a URL** like `https://github.com/owner/repo/pull/123`: extract `owner/repo` and `123` directly.

**From the current branch:**
```bash
gh pr view --json number,baseRepository \
  --jq '{number: .number, repo: (.baseRepository.owner.login + "/" + .baseRepository.name)}'
```

**From a branch name:**
```bash
gh pr view <branch-name> --json number,baseRepository \
  --jq '{number: .number, repo: (.baseRepository.owner.login + "/" + .baseRepository.name)}'
```

## Step 2 — Run the Script in the Background

Run the role-appropriate script (`./scripts/monitor-gh-pr.sh <REPO> <PR_NUMBER> [--interval <N>]` or `./scripts/monitor-gh-pr-review.sh <REPO> <PR_NUMBER> [--interval <N>] [--reviewer <login>]`). If you have a monitoring tool available, use it — the script exits 0 with a human-readable summary on stdout when something actionable is detected, which makes it a natural fit. When it exits, read its output and report to the user. Author mode: (1) whether CI passed or failed (naming any failing checks); (2) the count and type of any new comments; (3) a concrete next action. Reviewer mode: (1) whether the PR merged/closed; (2) new commits and their subjects; (3) whether a re-review was requested; (4) new comments/reviews — then offer to assess the delta against the posted review.

## Step 3 — Confirm to the User

Tell the user:
- The script is running and what it's watching (repo, PR number, poll interval)
- Where to find the output (monitor ID, PID, or log file path, depending on harness)
- How to stop it early (kill the PID, MonitorStop, or equivalent)

## Notes

- **State is stored** in `/tmp/monitor-gh-pr-<slug>-<pr>/` (author) and `/tmp/monitor-gh-pr-review-<slug>-<pr>/` (reviewer); override the root with `MONITOR_GH_PR_STATE_ROOT`. Delete the directory to reset the baseline so the next run re-reports existing events.
- **Exits on first event.** Start a new monitor after handling an event to keep watching. Reviewer mode exits for good on merge/close — don't re-arm after that.
- **The baseline swallows the current state.** The first run records existing comments (and, in reviewer mode, the current head and requested reviewers) without reporting them; only changes after that fire.
- **CI results are reported once per head commit** (author mode). Restarting the monitor on the same commit won't re-report an unchanged CI pass or failure; a new push resets this, so the next CI result is reported even if it matches the last one.
- **Poll interval guidance:** author — `--interval 30` for fast pipelines, `--interval 120` to reduce API calls on long ones; reviewer — the 300 default suits human turnaround, `--interval 1800` for a low-urgency background watch.
- **No checks yet?** (author mode) If the PR has no CI checks, the monitor watches only for comments until checks appear.
- **Tests:** `tests/test_monitor_gh_pr.sh` and `tests/test_monitor_gh_pr_review.sh` in the repo root cover both scripts with a stubbed `gh`.
