# Addressing an author-mode wake

What to do each time `monitor-gh-pr.sh` reports on a PR you authored, until the PR is done. If whoever started the watch set a different stop point (a time cap, report-only), theirs wins.

## Comments and reviews

Read every new comment and review, including bots, then sort each one:

- **Non-controversial:** a clear, local change you agree with (a nit, a rename, a missing test, a typo, a real bug in this PR). Fix it, commit and push. After the push, react 👍 on the comment and resolve its thread. No reply text.
- **Controversial:** you disagree, the fix changes scope, behaviour or design, reviewers disagree with each other, or it asks about intent. Investigate (read the code, history, precedent) and bring what you found to the user: in your session, or through your supervisor if you have one. Leave code and thread alone until the user decides.

Verify a bot finding before fixing it; a false positive goes to the user as controversial, with the evidence.

Commands (`<repo>` is `owner/repo`):

```bash
# 👍 on an inline review comment, or on a PR conversation comment
gh api -X POST "repos/<repo>/pulls/comments/<comment-id>/reactions" -f content=+1
gh api -X POST "repos/<repo>/issues/comments/<comment-id>/reactions" -f content=+1

# thread ids, to resolve the thread of a given comment
gh api graphql -f query='query { repository(owner: "<owner>", name: "<name>") { pullRequest(number: <n>) {
  reviewThreads(first: 100) { nodes { id isResolved comments(first: 1) { nodes { databaseId author { login } body } } } } } } }'
gh api graphql -f query='mutation { resolveReviewThread(input: { threadId: "<thread-id>" }) { thread { isResolved } } }'
```

## CI

On a failing check, read its log (`gh run view <run-id> --log-failed`). If this PR caused it, fix it like a non-controversial comment. If it looks unrelated or flaky, tell the user instead of changing code for it.

## Re-requesting review

Check the state after each push and on each wake:

```bash
gh pr view <n> --repo <repo> --json reviewDecision,latestReviews,reviewRequests
```

- Once every comment is addressed (fixed and resolved, or settled by the user) and the PR is not approved, re-request review from the reviewers who commented: `gh pr edit <n> --repo <repo> --add-reviewer <login>`.
- When a push or a rebase dismisses an approval (`latestReviews` shows `DISMISSED` where it was `APPROVED`), re-request that reviewer the same way.

## Re-arm until done

Re-arm the watcher after every wake until all three hold, then stop and report:

- `reviewDecision` is `APPROVED`
- no unresolved review threads
- CI passing
