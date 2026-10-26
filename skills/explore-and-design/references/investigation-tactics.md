# Investigation Tactics

The moves that turn an ambiguous prompt into evidence a design can stand on.

## Evidence ladder

Work top-down. Each rung is slower and less reliable than the one above it.

1. **Local source** in the repo or worktree. Record the branch and commit; a finding without a commit goes stale on the next rebase.
2. **History and intent.** `git log -S`/`git blame` for why code looks the way it does; the PR that introduced it and its review threads (`gh pr view`, `gh api`).
3. **Dependency source at the deployed version.** Check the version in the lockfile, then read that version's source (`node_modules`, or `gh api repos/<org>/<repo>/contents/<path>?ref=<tag>`). HEAD of a library is not what production runs.
4. **Real data.** Production logs, metrics, and traces through the Datadog MCP; warehouse tables through Databricks; a live call against a vendor sandbox; a run against the local stack. See below.
5. **People's context.** The ticket and its comments, Slack threads, the Notion TSD, prior design docs in `~/.ai/wip/`. These tell you what was decided and what's contested. They are claims to verify against rungs 1 to 4, not ground truth.
6. **Docs and web search.** Last resort for undocumented vendor behavior. Prefer the vendor's API reference over blog posts, and confirm with a sandbox call when you can.

## Real-data probes

When a design choice hinges on "does this actually happen?":

- **Datadog** (logs, APM traces, metrics): confirm the service and environment before concluding "no results". Narrow the time window and query, but check that the narrowed query can still match what you're looking for.
- **Databricks / warehouse**: get the query itself adversarially reviewed when the result is load-bearing. Overly broad `LIKE` patterns and wrong join keys produce confident wrong counts.
- **Vendor sandbox** (for example a Workato dev workspace): build the smallest test artifact that exercises the uncertain behavior, fire it, and capture the raw response to a file before reshaping it. Record what you created so it can be reused or cleaned up.
- **Local stack**: reproduce with real fixtures. If the environment fights you (missing env files, docker state), note the setup steps in the doc's reproduction notes.
- **Sample data the user is designing around**: `head`/`wc -l`/`jq` the actual file before suggesting a data model.

When the data shows nothing, say "no evidence found with query X over window Y", not "it doesn't happen". Negative evidence needs the are-you-sure ladder.

## The are-you-sure ladder

Confidence interrogation for results that feel too clean, especially negative ones. The moves the user reaches for:

- *"are you _sure_ double check your work, assume you did something wrong in your search"*
- *"are you sure control_type doesn't show up? I thought we established that it did?"*
- *"how sure are you this is the cause?"*
- *"double check what the versions are"*
- *"what have I asked the last 2 times regarding double checking?"*

When a "can't be done" or "no problem found" conclusion forms early, reopen it with the underlying mechanism question:

- *"can you answer this question yourself?"*
- *"why wouldn't you be able to create a query that would match what [that service] is doing?"*
- *"Is it even possible to actually end up there at this point?"*

Finding nothing feels like being done. Treat that feeling as a signal to search a second way: a different query, a different data source, a different spelling.

## Push fixes toward prevention layers

Ask whether a proposed fix sits in the right place. A local fix is often correct, while a higher layer would eliminate the whole class of bug:

- A null-guard at one call site → a type that makes the bad state unrepresentable.
- A new hand-rolled check → the existing library hook or helper that already does it.
- A check at the route → a schema-level constraint so the bad call can't be made at all.

Both layers can land together when each is tightly scoped.
