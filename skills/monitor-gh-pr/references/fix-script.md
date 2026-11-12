# Briefing a fix for a misbehaving watcher

Open this only after the user agreed to a fix. Use whatever delegation your harness has (a subagent, a task agent, a background worker). Without one, give this brief to the user to hand off.

The brief carries:

- **The symptom and the evidence:** the script output and the `gh` call that contradicts it.
- **The source repo:** the installed skill directory is usually a symlink, so resolve it with `cd <skill dir> && pwd -P && git rev-parse --show-toplevel`. Fixes land there; the installed copy stays untouched.
- **The script and its test:** `skills/monitor-gh-pr/scripts/<script>` and its stubbed-`gh` test, `tests/test_monitor_gh_pr.sh` (author) or `tests/test_monitor_gh_pr_review.sh` (reviewer), in that repo.
- **The rules:** work on a new branch or worktree; write a failing test that reproduces the symptom first; fix; run both test files and `shellcheck` on the script; commit locally; leave pushing and installing to the user; report the commit SHA.

When it reports back, tell the user the commit and that the fix reaches the running watch only once the user installs it.
