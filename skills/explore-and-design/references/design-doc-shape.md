# Design Doc Shape

The structure that recurs across `design/admin-api-types.md`, `design/task-registry.md`, `design/flow-tasks-sdk.md`, `design/sdk-overview.md`, `pi-fleet/spec.md`, and several `~/.ai/wip/*.md` investigations.

The common opener is `# <Title>` → one-paragraph intent (what the doc is for) → optional sister-design link → a first `##` section that names what the doc anchors on. **No "Status / Audience / Scope" preamble.** What that first section is named varies with the doc's framing:

- **`## Problem`** — greenfield work where the problem isn't obvious (`admin-api-types.md`, `task-registry.md`).
- **`## What we ARE typing` / `## The runtime contract`** — sister-design or layered-overview docs where the framing is what the design *covers*, not the problem (`flow-tasks-sdk.md`, `sdk-overview.md`).
- **`## Status` then `## Background` then `## Goals` / `## Non-Goals`** — spec docs that **replace an earlier draft**. The `## Status` paragraph says "Second draft, ..." and links the prior version (`pi-fleet/spec.md`).

Pick the framing that fits. The one rule is no "audience / scope" preamble pretending to be metadata — just lead with the substance.

## Problem (or equivalent first section)

One paragraph. What is the problem we're solving — or, if the doc is framed differently, what is the design's anchor? Frame it in terms of the user / system, not the proposed solution.

## What exists today (or "Background")

An **inventory table** of relevant existing artifacts. One row per artifact, columns roughly:

| Artifact | Path | Notes / Verdict |

The "Verdict" column is load-bearing — it forces a decision per artifact (Drop / Wrap / Adopt / Out of scope / etc.). For each artifact that's NOT usable as-is, write a sub-section explaining why. This is where similar-but-different artifacts get disambiguated.

Quantify when you can: paste the actual count-table output (e.g. "189 tasks → 101 Trigger / 35 Mutation / 29 PrimitiveAction / 23 Fetch / 1 AdminApiOperation") instead of "lots of tasks of different kinds." Numbers in a design doc must be the literal output of a command you ran in this session — don't paraphrase or round.

## Architecture / data flow

ASCII box-and-arrow diagram across the system boundaries. Label each box with what it owns (Flow Rails app / SDK build pipeline / user project / etc.) and each arrow with what crosses it (rake task / API endpoint / pnpm script / file).

```
┌──────────────────────────────────────────────────────────────┐
│ Flow (Rails app)                                             │
│   rake schema:export_sdl                                     │
│         │                                                    │
│         ▼                                                    │
│  schema/sdk-exports/<api_version>.graphql  (committed)       │
└──────────────────────────────────────────────────────────────┘
                            │
                            ▼ (at SDK release time, NOT user runtime)
┌──────────────────────────────────────────────────────────────┐
│ SDK build pipeline                                           │
│   curl …/admin-graphql-schema/latest.graphql                 │
└──────────────────────────────────────────────────────────────┘
```

## What we are NOT doing (non-goals)

Explicit, bulleted. Examples:

- *"No automated worktree / branch creation. Manager LLM owns cwd choice."*
- *"No persisted manager-LLM context. The registry stores facts about workers, not the manager's reasoning."*
- *"First-party Flow connector tasks are not typed; users hit them via the admin-api codegen instead."*

If a non-goal punts to a sister design, link it: *"See task-registry.md for the third-party-extensions case."*

## Accepted simplifications

Name the trade-offs you've deliberately made. The reader should know this is not an oversight.

- *"Metafield value types stay `String!` — no shop-specific helper in v1. Parsing the value is the script's concern."*
- *"Workers are TUI mode only — no `--mode json -p` workers."*

## Open questions / known risks

Numbered. For each: **Proposed: X. Alternative: Y. Need user call.** OR **Risk: Z. Evidence it won't materialize: ….**

```
1. fleet_send sync vs async. Proposed: fire-and-forget, return
   {delivered:true} once intercom accepts the message; manager can poll
   fleet_status for ack. Alternative: tool blocks up to N seconds for an
   ack. Sync feels nicer for the LLM but couples the tool call to worker
   turn latency. Need user call.

2. Windows naming collisions. ...
```

Don't bury these. They are an active part of the design.

## Sister-design references

If this is one of several related designs, link them explicitly: *"Sister design to admin-api-types.md (typed Admin API client) and flow-tasks-sdk.md (first-party tasks). Together these cover…"*. The pattern of *"running the same design rhythm twice on parallel-but-non-identical problems"* is deliberate; cross-linking is how it stays coherent.

## Prototype status (when applicable)

What landed in which commits, what's still stubbed, what's verified. Specifically: which guards have been demonstrated (e.g. "verified: bad field → tsc error; denied mutation → schema-level error; missing required var → tsc error"). Investigation-style docs use a similar section for "what we checked and what we found."

## Prior-art scan shape (when one is included)

Rare, only when triggered. Structure:

- **Headline verdict** in bold up top: *"Yes — Batty is a remarkably close match"* or *"No off-the-shelf option fits all four properties simultaneously."*
- **Closest matches** — one entry per candidate. Each with:
  - GitHub / homepage link
  - 2-3 bullets on what overlaps
  - 2-3 bullets on what doesn't fit
  - **Fit score** (rough %) — forces a quantitative comparison
- **Adjacent patterns worth knowing** — things that aren't a direct fit but inform the design
- **Search notes** — what queries you ran, what you ruled out. Makes the search reproducible and surfaces gaps.
- **Action recommendation** — *"Mihai should read the dev.to posts and `batty init` it into a throwaway dir for an hour before writing more pi-fleet code."*

## Style

- No code in the doc except small snippets that illustrate a shape. Algorithms in prose.
- Specific real names, not greek-letter placeholders.
- "Why" before "what" when describing a decision.
- Strip judgement calls from investigation reports before they ship to issues — observations + evidence, not opinions.
