---
name: monitor-gh-pr
description: Monitor a GitHub PR for CI failures, CI success, and new comments (including inline review comments). Runs a polling script in the background and notifies you when something actionable happens. Use after pushing to a branch while doing other work. Trigger phrases include "watch my PR", "monitor PR #N", "notify me when CI is done", "background CI watch", "let me know if there are new comments".
license: MIT
metadata:
  category: github
---

# Monitor GitHub PR

Run `./scripts/monitor-gh-pr.sh` in the background. It polls until something actionable happens — CI fails, CI passes, or new comments arrive — then prints a summary to stdout and exits 0.

## When to Use

Use after pushing to a branch when you want to keep working on something else while CI runs. The script handles the polling; your job is to run it in the background using whatever mechanism your harness provides and surface its output when it exits.

## Inputs

| Input | Description | Example |
|-------|-------------|---------|
| `REPO` | `owner/repo` | `MaintainX/maintainx` |
| `PR_NUMBER` | PR number | `38873` |
| `--interval N` | Poll interval in seconds (default: 60) | `--interval 120` |

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

Run `./scripts/monitor-gh-pr.sh <REPO> <PR_NUMBER> [--interval <N>]` in the background using whatever mechanism your harness provides for background execution with completion notification. The script exits 0 with a human-readable summary on stdout when something actionable is detected.

When it exits, read its output and report to the user: (1) whether CI passed or failed (naming any failing checks); (2) the count and type of any new comments (regular vs. inline review); (3) a concrete next action.

## Step 3 — Confirm to the User

Tell the user:
- The script is running and what it's watching (repo, PR number, poll interval)
- Where to find the output (monitor ID, PID, or log file path, depending on harness)
- How to stop it early (kill the PID, MonitorStop, or equivalent)

## Notes

- **State is stored** in `/tmp/monitor-gh-pr-<slug>-<pr>/`. Delete this directory to reset the comment baseline so the next run re-reports existing comments.
- **Exits on first event.** Start a new monitor after handling an event to keep watching.
- **Poll interval guidance:** `--interval 30` for fast pipelines, `--interval 120` to reduce API calls on long ones.
- **No checks yet?** If the PR has no CI checks, the monitor watches only for comments until checks appear.
