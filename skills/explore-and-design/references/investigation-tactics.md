# Investigation Tactics

The specific moves that turn an ambiguous prompt into a settled design.

## Source-vs-docs hierarchy

Always work top-down:

1. **Local source** — `grep`/`read`/`cat` in the repo or in `~/world/trees/<tree>/src/areas/<zone>/`. Cheapest, freshest, most accurate.
2. **Upstream gem/library source** — `gh api repos/<org>/<repo>/contents/<path>?ref=<tag>` for the specific deployed version. Crucial: check the actual version in the lockfile, not the latest on GitHub. *"keep in mind that we're not on version 4."*
3. **Dev-gem unpacks** — `.dev/gem/gems/<name>-<version>/` if Shopify-dev mode has materialized it.
4. **Peer LLM verification** — spawn `pi -p` or `claude -p` against a separate harness to ask it about its own behavior (e.g. argument substitution semantics).
5. **Docs / wikis / web search** — last resort, often inadequate. Use when source is genuinely opaque (e.g. proprietary docs, undocumented API quirks).

Whenever you quote a snippet in a finding, **state its provenance** — file path, ref, line. *"Where is that snippet from?"* is a question you should be ready for.

## Real-data probes

When a design choice depends on "does this actually happen?":

- **BigQuery** — `bq query --use_legacy_sql=false` against warehouse tables like `apps_and_developers.flow_config_field_values_v1` joined to `shopify_flow.workflows_v1` for `is_active`. The query itself is suspicious — get it adversarial-reviewed (the `%2f` false-positive trap is real).
- **Observe** — `observe_query` against the right dataset (`flow-production` not `core` for Flow work), or `observe_error_groups` filtered by `resource.service.name`. PromQL for metric existence checks.
- **Rails-runner against a real shop** — for Flow work, `bundle exec rails runner` inside a Flow checkout, talking to a real test shop with the apps you care about actually installed. Capture the response **raw to a file** — *"like don't parse it"* — and reshape later from the fixture.
- **Real CSVs / sample data** — `head`/`awk`/`wc -l` the actual file the user is designing around before suggesting any data model.

When you can't find evidence in the data, **say so** — don't infer it doesn't exist. Negative evidence needs the are-you-sure ladder.

## The adversarial-subagent loop

SKILL.md Rule 4 covers when to reach for `adversarial-review` / `adversarial-review-loop` and what triggers them. The investigation-specific add-on: **even subagent findings get verified.** If a subagent reports "0 active workflows match," re-run the query yourself before accepting the refutation; don't trust the subagent's empirical claim any more than your own. The framing is *trust but verify*, applied recursively to the refutation itself.

## The "are you _sure_?" ladder

Confidence interrogation, especially on results that confirm what the agent wanted to find. The verbatim moves the user reaches for (across multiple sessions and unrelated investigations):

- *"are you _sure_ double check your work, assume you did something wrong in your search"*
- *"are you _sure_ _sure_?"*
- *"how sure are you this is the cause?"*
- *"double check what the versions are"*

These are not a fixed N-step ladder — they're a class of follow-up to apply when a result feels too clean. Negative results need this kind of follow-up more than positive ones — *finding nothing feels like being done*, which is a bias to fight. The signature move is repeating the doubt: *"what have I asked the last 2 times regarding double checking?"* — a clean answer once is not enough.

## Distinguish similar-but-different

When two artifacts could be conflated, force the distinction into the design doc:

- Read both. Don't trust naming.
- Document the difference with a concrete example.
- If the conflation is a recurring trap, capture it as a knowledge file (`knowledge/<topic>.md`).

Known traps in this codebase:
- Flow processed `schema/graphql/<v>.json` ≠ raw Admin API introspection
- Maestro function name (directory) ≠ user-facing Task id (registry)
- Gem v3.1.7 (deployed) ≠ v4.0.0 (HEAD)

## Push back on premature negatives

When the agent forms a "can't be done" / "internal mesh only" / "no problem found" conclusion early, **re-open it by asking the underlying mechanism question**:

- "Why wouldn't you be able to create a query that matches what Cusco does?"
- "How does this primitive work, does it use oauth or jwt?"
- "Could we narrow down the log search but still catch what we're looking for?"

The pattern: when the conclusion is negative, *the investigation was probably incomplete*.

## Push fixes toward prevention layers

When you have a fix proposal, ask "is the fix in the right place?". Often the local fix is correct but a higher prevention layer would eliminate the *class* of bug:

- A nil-guard at one call site → a typed `fulfill` on the base class so Sorbet flags it everywhere
- A new path-traversal detector → reuse the gem's existing `http_request_allow_path_traversal_callback`
- A schema check at the route → an SDL-level denylist so the operation can't be called at all

Both layers can land in the same PR if they're tightly scoped.

## When investigation surprises you, reverse the design

The plan is a hypothesis. If a concrete test invalidates the premise — `pi prompt templates don't substitute $@`, partner_action label got renamed upstream, the bumped gem version doesn't ship the feature you thought — **uninstall, restructure, redo**. Don't salvage. Don't apologize.

## Tools available in this codebase

- `gh api` / `gh pr view` / `gh issue view` — issue and PR context
- `tool_gateway_*` MCPs — Vault, Slack, BigQuery, internal docs
- `observe_*` MCPs — logs, metrics, error groups, traces
- `bundle exec rails runner` — execute Ruby in a real Flow context
- `pi -p` / `claude -p` — fire a separate harness for peer verification
- Subagents (`worker`, `delegate`, `scout`) — fresh-context refutation primitives

## Investigation output

Investigations don't always produce a `design/` doc. Common outputs:

- **GitHub issue comment** — risk + evidence-against summary. Judgement calls stripped. *"Remove the judgement calls."*
- **PR description** — WHAT / WHY / Testing / Review-tip per the Flow team's template
- **Draft inline PR comment** — name the smell, show one concrete alternative shape, justify with a caller audit
- **Knowledge file** in `~/.pi/memory/knowledge/<topic>.md` — when a trap surfaced is durable across future sessions
- **WIP scratchpad** in `~/.ai/wip/<topic>-<date>.md` — when the work isn't ready to land somewhere permanent

The `design/` doc is one of several artifacts; pick the right one for the context.
