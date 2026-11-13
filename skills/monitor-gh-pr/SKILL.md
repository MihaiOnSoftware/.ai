---
name: monitor-gh-pr
description: Watches a GitHub PR in the background and reports what needs attention, as author (CI and comments, then addresses them) or as reviewer (new activity, with an opt-in re-review of new pushes). Use for "watch my PR", "monitor PR #N", "tell me when CI is done", "tell me when they reply or push", "babysit this PR until it merges", "re-review if changes come in and re-approve if my comments are resolved". Not for running a review itself; use your review process for that.
metadata:
  category: github
---

# Monitor GitHub PR

A script polls the PR and exits 0 with a summary on stdout at the first actionable event. The watcher is that script running in the background: you launch it, act on its report, and re-arm it until the PR is done.

## Inputs

| Flag | When to set it |
|---|---|
| `--interval N` | Author default 60s: 30 for fast pipelines, 120 for long ones. Reviewer default 300s for human turnaround: 1800 for a low-urgency watch. |
| `--reviewer LOGIN` | Reviewer mode, when the review is not the gh user's own (default: the gh user). |
| `--rereview MODE` | Reviewer mode, `confirm` or `auto-approve`, only when the reviewer asks for the re-review watch on this PR. |

## Step 1 — Resolve the PR and Your Role

- **From a URL** like `https://github.com/owner/repo/pull/123`: take `owner/repo` and `123`.
- **From a branch** (omit `<branch>` for the current one):

  ```bash
  gh pr view [<branch>] --json number,author,baseRepository \
    --jq '{number, author: .author.login, repo: (.baseRepository.owner.login + "/" + .baseRepository.name)}'
  ```

Your role is **author** when the PR's author is the gh user (`gh api user --jq .login`), **reviewer** otherwise. If the user wants both CI and review events, ask which role to watch as.

Done when you have the repo, the PR number and the role. If `gh pr view` finds no PR or the URL does not parse, ask the user for the PR URL. If `gh auth status` fails, report it and stop: the scripts read API failures as "nothing new" and would watch in silence.

## Step 2 — Launch the Watcher

| Role | Command | Reports |
|---|---|---|
| Author | `./scripts/monitor-gh-pr.sh <REPO> <PR_NUMBER> [--interval N]` | CI failures, CI success, new comments and reviews |
| Reviewer | `./scripts/monitor-gh-pr-review.sh <REPO> <PR_NUMBER> [--interval N] [--reviewer LOGIN] [--rereview MODE]` | merge/close, new commits with subjects, re-review requests, dismissals of the reviewer's reviews, new comments and reviews |

Run it in the background (a monitoring tool if your harness has one). Done when the first poll has logged `Watching ...` and no error.

## Step 3 — Confirm to the User

Tell the user what the watcher is watching (repo, PR number, role, poll interval, and the re-review mode if armed), where its output goes (monitor ID, PID or log file), and how to stop it early (kill the PID, MonitorStop, or equivalent).

## Step 4 — On Exit, Report and Act

Read the summary, report it, act, then re-arm by running the same command again. The baseline carries over, so only newer events fire.

**Author:**
- Report whether CI passed or failed (naming failing checks) and the new comments by count and type.
- Address them with [references/address-comments.md](references/address-comments.md), which defines non-controversial (fix, push, 👍, resolve) and controversial (investigate, bring to the user), fixes CI the PR broke and re-requests review.
- Re-arm until the PR is approved, has no unresolved threads and CI passes, or until the user, or whoever started the watch, sets another stop point.

**Reviewer:**
- On merge/close, report it and end the watch.
- Otherwise report new commits and their subjects, a re-review request, dismissals of the reviewer's reviews, and new comments and reviews.
- Offer to assess the delta: each posted comment as addressed, unaddressed or a new concern, citing the commit. With `--rereview` armed, run the re-review watch instead (below).
- Re-arm until merge/close or until the user says stop.

## Re-review Watch (Reviewer, Opt-in)

Arm `--rereview` only when the reviewer asks for it on this PR; you may mention the option when you start a plain reviewer watch. Each report then ends with a `## Re-review` block. On every such wake, follow [references/rereview.md](references/rereview.md), which owns the arming rules, the re-review, the approval gate and what may be posted.

## When the Watcher Misbehaves

Suspect a bug in the script when:

- The output carries a raw API body (`{"message": ...}`, `Not Found`, HTML) or a jq or bash error.
- The script exits non-zero with no usage message, or dies mid-poll.
- A report disagrees with live state: `gh pr view <n> --repo <repo>` and the API show something the watcher missed, or it fires on something that did not happen. [references/watcher-behaviour.md](references/watcher-behaviour.md) says what each event should do.

Then confirm it with one read-only `gh` call that shows the disagreement, keep watching only if the rest of the output is still trustworthy, and tell the user what broke, the evidence and the impact on the watch. Offer to have a fresh subagent fix the script at its source, and on the user's yes brief it from [references/fix-script.md](references/fix-script.md). Report only what the watcher and your `gh` check show.
