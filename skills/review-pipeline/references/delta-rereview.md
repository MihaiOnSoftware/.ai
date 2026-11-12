# Delta re-review

A `monitor-gh-pr` re-review wake runs this pipeline on the author's new commits only. What changes:

- **Target** is the range `<reviewed-sha>..<head-sha>` from the watcher's `## Re-review` block. The reviewers review the delta and may read the whole PR at `<head-sha>` for context.
- **Phase 1b also runs the resolution check.** It alone gets the reviewer's earlier comments with their replies, and returns one status per comment (ADDRESSED / ANSWERED / DEFERRED / OPEN, defined in monitor-gh-pr's `references/rereview.md`) with its evidence. The other reviewers do not see the earlier comments, so they do not anchor on them.
- **Phase 2** appends the resolution table to the merged draft unchanged. The shaper drops findings the earlier review already made.
- **The checkpoint** surfaces the resolution table, the shaped delta comments and the gate result from that file, and asks for the go the way that file says. The empty-body approval is the default proposal on a passing gate.

Everything else, including "nothing is posted without the user's go", is unchanged.
