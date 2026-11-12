---
name: monitor-gh-pr
description: Monitor a GitHub PR for actionable events. Two scripts, picked by role — author mode (monitor-gh-pr.sh) watches CI results and new comments after you push; reviewer mode (monitor-gh-pr-review.sh) watches a PR you are reviewing for merge/close, new commits, re-review requests, dismissed reviews, and new comments, with an opt-in re-review mode that re-reviews pushes and proposes a re-approval. Trigger phrases include "watch my PR", "monitor PR #N", "notify me when CI is done", "background CI watch", "let me know if there are new comments", "watch this PR for re-requests", "tell me when they push changes", "re-review if changes come in", "re-approve if my comments are resolved".
metadata:
  category: github
---

# Monitor GitHub PR

Two polling scripts, picked by your role on the PR. Both run until something actionable happens, print a summary to stdout, and exit 0.

| Your role | Script | Watches |
|---|---|---|
| **Author** — you wrote/pushed the PR | `./scripts/monitor-gh-pr.sh` | CI failures, CI success, new comments |
| **Reviewer** — you are reviewing someone else's PR | `./scripts/monitor-gh-pr-review.sh` | merge/close, new commits (with subjects), re-review requests, dismissals of the reviewer's reviews, new comments and reviews |

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
| `--reviewer LOGIN` | reviewer only | Login whose re-review requests and dismissed reviews get flagged prominently (default: the gh-authenticated user) | `--reviewer MihaiOnSoftware` |
| `--rereview MODE` | reviewer only | Opt-in re-review mode, `confirm` or `auto-approve`; only when the reviewer asked for it on this PR (see Re-review watch) | `--rereview confirm` |

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

Run the role-appropriate script (`./scripts/monitor-gh-pr.sh <REPO> <PR_NUMBER> [--interval <N>]` or `./scripts/monitor-gh-pr-review.sh <REPO> <PR_NUMBER> [--interval <N>] [--reviewer <login>] [--rereview <mode>]`). If you have a monitoring tool available, use it — the script exits 0 with a human-readable summary on stdout when something actionable is detected, which makes it a natural fit. When it exits, read its output and report to the user. Author mode: (1) whether CI passed or failed (naming any failing checks); (2) the count and type of any new comments; (3) a concrete next action. Reviewer mode: (1) whether the PR merged/closed; (2) new commits and their subjects; (3) whether a re-review was requested; (4) dismissals of the reviewer's reviews; (5) new comments/reviews — then offer to assess the delta against the posted review, or, with `--rereview`, follow the re-review steps.

## Step 3 — Confirm to the User

Tell the user:
- The script is running and what it's watching (repo, PR number, poll interval)
- Where to find the output (monitor ID, PID, or log file path, depending on harness)
- How to stop it early (kill the PID, MonitorStop, or equivalent)

## Optional: Re-review Watch (reviewer mode)

Off by default. With `--rereview`, every report ends with a `## Re-review` block (the reviewer's last verdict and its commit, the range to re-review, the threads he opened) and you re-review on each wake, then propose a re-approval when his comments are resolved and the only new findings are nits or nothing. The script never posts; you post only on his explicit go, except the one bodyless approval that `auto-approve` allows on a clean gate.

Read [references/rereview.md](references/rereview.md) before arming it and on every wake. It covers the arming rules, the resolution check, the gate, how the confirmation reaches him, posting, and dismissed approvals. You may mention the option when you start a plain reviewer watch; never arm it unasked.

## Notes

- **State is stored** in `/tmp/monitor-gh-pr-<slug>-<pr>/` (author) and `/tmp/monitor-gh-pr-review-<slug>-<pr>/` (reviewer, including the reviewer's review states that dismissals are compared against); override the root with `MONITOR_GH_PR_STATE_ROOT`. Delete the directory to reset the baseline so the next run re-reports existing events.
- **Exits on first event.** Start a new monitor after handling an event to keep watching. Reviewer mode exits for good on merge/close — don't re-arm after that.
- **The baseline swallows the current state.** The first run records existing comments (and, in reviewer mode, the current head and requested reviewers) without reporting them; only changes after that fire.
- **CI results are reported once per head commit** (author mode). Restarting the monitor on the same commit won't re-report an unchanged CI pass or failure; a new push resets this, so the next CI result is reported even if it matches the last one.
- **Poll interval guidance:** author — `--interval 30` for fast pipelines, `--interval 120` to reduce API calls on long ones; reviewer — the 300 default suits human turnaround, `--interval 1800` for a low-urgency background watch.
- **No checks yet?** (author mode) If the PR has no CI checks, the monitor watches only for comments until checks appear.
- **Dismissals fire on the state change.** A dismissed review keeps its id, so the watcher compares the reviewer's review states between polls; a review already dismissed at baseline never fires.
- **Re-review flags fire on the transition into the requested set.** GitHub drops a reviewer from pending requests once they submit a review, so a request already pending at baseline never fires "re-review requested"; only a fresh re-request after the watch starts does.
- **Tests:** `tests/test_monitor_gh_pr.sh` and `tests/test_monitor_gh_pr_review.sh` live in the source repo (`MihaiOnSoftware/.ai`), not in the installed skill directory; they cover both scripts with a stubbed `gh`.
