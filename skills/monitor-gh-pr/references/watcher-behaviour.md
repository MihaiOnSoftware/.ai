# How the watcher behaves

What each event should and should not do, for telling a real bug from expected behaviour.

- **State** lives in `/tmp/monitor-gh-pr-<slug>-<pr>/` (author) and `/tmp/monitor-gh-pr-review-<slug>-<pr>/` (reviewer); `MONITOR_GH_PR_STATE_ROOT` overrides the root. Deleting the directory resets the baseline, so the next run re-reports existing events.
- **The first run records a baseline** without reporting it: existing comments and reviews, and in reviewer mode the head, the requested reviewers and the reviewer's review states. Only changes after that fire.
- **One event per run.** The watcher exits on the first actionable poll; re-arming starts the next watch from the saved baseline.
- **CI is reported once per head commit** (author). Re-arming on the same commit does not repeat an unchanged pass or failure; a new push resets it. A PR with no checks yet is watched for comments only until checks appear. Manual approval gates (`WAITING`) do not hold up a pass.
- **Dismissals fire on the state change** (reviewer): a review already dismissed at baseline never fires.
- **Re-review requests fire when the reviewer enters the requested set** after the watch starts; a request already pending at baseline never fires.
- **A force-push or rebase** shows as `force-push or rebase: <old> → <new>` instead of a commit list.
- **API failures read as "nothing new"**, except an HTTP error body leaking into the output, which is a bug.
