---
name: monitor-gh-pr
description: Monitor a GitHub PR in the background for CI failures, CI success, and new comments (including inline review comments). Use after pushing to a branch while doing other work. Trigger phrases include "watch my PR", "monitor PR #N", "notify me when CI is done", "background CI watch", "let me know if there are new comments".
license: MIT
metadata:
  category: github
---

# Monitor GitHub PR

Run a background watcher on a PR that exits and notifies you when something needs attention: CI fails, CI passes, or new comments arrive (regular PR comments or inline review comments).

## When to Use

Use after pushing to a branch when you want to keep working on something else while CI runs. The script polls in the background and surfaces a summary the moment something is actionable.

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

## Step 2 — Start the Monitor

The monitoring script lives at `../../scripts/monitor-gh-pr.sh` relative to this skill file. Resolve the absolute path before calling MonitorCreate.

```
MonitorCreate({
  command: "<resolved-absolute-path>/monitor-gh-pr.sh <REPO> <PR_NUMBER> [--interval <N>]",
  description: "Watch <REPO>#<PR_NUMBER> for CI and comments",
  onDone: "The background monitor for <REPO>#<PR_NUMBER> finished. Read its last output and: (1) state whether CI passed or failed, and name any failing checks; (2) report the count and type of any new comments (regular PR comments vs. inline review comments); (3) suggest a concrete next action. Be specific."
})
```

## Step 3 — Confirm to the User

After calling MonitorCreate, tell the user:

- The monitor is running (include the monitor ID so they can stop it)
- What it's watching: repo, PR number, poll interval
- That you'll automatically surface a summary when something actionable happens
- To stop early: `MonitorStop("<monitor-id>")`

## Notes

- **State is stored** in `/tmp/monitor-gh-pr-<slug>-<pr>/`. Delete this directory to reset the comment baseline, which causes the next run to re-report all existing comments.
- **Exits on first event.** The monitor exits after detecting the first actionable event. To keep watching after handling an event, start a new monitor.
- **Poll interval guidance:** use `--interval 30` for fast pipelines, `--interval 120` to reduce GitHub API calls on long ones.
- **No checks yet?** If the PR has no CI checks configured, the monitor watches only for comments until checks appear.
