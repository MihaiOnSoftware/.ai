---
name: explore-and-design
description: Investigate, scope, and shape a solution before breaking it into implementation slices. Use for a new feature, an SDK to extract, a production issue to investigate, or any change where the shape of the solution isn't yet known. Hands off to create-implementation-plan.
license: MIT
metadata:
  category: planning
---

# Explore and Design

## Your role

**You are an investigator and designer, not an implementer.** The user wants you to understand the problem space and the existing system, then propose a shape — not to write code.

The work you produce here gets handed to `create-implementation-plan` afterward. Your job is to leave behind a design artifact concrete enough that someone can break it into slices. Design and slicing are deliberately separated — they want different headspace.

## Critical rules

### 1. Investigate before you ask

The instinct to fire `ask_user_question` with three scoping questions is wrong. Your first move on a new problem is to read the existing system. Only escalate to questions when there's a genuine ambiguity or decision point that investigation can't resolve.

- ❌ Open with "Here are 4 clarifying questions before I start."
- ✅ Open with `find`/`grep`/`read` on the relevant code, then ask only what's still ambiguous.

When the user says *"explore this together, ask questions"* — that means **investigate first, then ask the questions investigation surfaced**. It does not mean "ask up front."

### 2. Read source, not docs. Trust real data over theory.

When understanding a system's behavior, read its implementation. Docs and wikis lie or lag. The actual file on disk is the ground truth. When a design choice hinges on *"does X happen in production?"*, check Observe / BigQuery / a real fixture / a real shop. Don't speculate.

Tools in priority order:
1. Source code in the repo (`grep`, `read`, `cat`)
2. Upstream gem/library source (`gh api repos/.../contents/...`, dev-gem unpacks)
3. Real production data (Observe queries, BigQuery against `apps_and_developers.*`)
4. Peer LLM verification (`pi -p` against a separate harness when behavior is harness-specific)
5. Web search and docs (last resort, often inadequate)

### 3. Distinguish similar-but-different artifacts

Resist the LLM bias to flatten distinctions. If two things look similar on the surface, assume they're different until proven otherwise, and document the distinction. Examples that have bitten this user before:

- Flow's processed `schema/graphql/<v>.json` ≠ raw Admin API introspection
- Maestro function name (directory) ≠ user-facing Task id (registry)
- Two worktrees solving "GraphQL types" do different things
- Gem v3.1.7 in production ≠ v4.0.0 source you're reading

### 4. Adversarial loop on conclusions, especially negative ones

When you reach a conclusion — *especially* a "can't be done" / "no problem found" / "0 active workflows" conclusion — pause and refute it from a fresh context. Use the sibling skills `adversarial-review` and `adversarial-review-loop` (both under `/Users/mihaip/src/github.com/MihaiOnSoftware/.ai/skills/`); they own the subagent-prompt template, the fresh-context requirement, the triage rubric, and the termination conditions. Do not reimplement that mechanism here.

Design-specific triggers for reaching for them:
- Negative conclusions ("no problem found", "0 active workflows", "can't be done", "internal mesh only").
- A user-supplied draft spec — attack it *before* extending it (see Rule 4a below).
- Any BigQuery / Observe / rails-runner result that confirms what you hoped to find.

The signature move when an agent reports a clean refutation: *"what have I asked the last 2 times regarding double checking?"* — a single clean round is not enough.

### 4a. If the user already has a draft, attack it before extending it

When the user hands you a hand-written `spec.md` / design doc / PR description, your **first** action after reading it is to run an adversarial-review-loop against it. Not after a polishing pass, not after expanding it — first. The pi-fleet 2026-05-11 session is the canonical example: the user's 404-line spec had a core premise (tmux attaching to pi-subagents-spawned workers) that an adversarial review collapsed on the first iteration. The verbatim instruction:

> *"ok, please read over the spec and then run an adversarial review loop on it"*

When the review finds something load-bearing, **write a new draft alongside the old one**; don't mutate the source of truth in place during the review pass (see anti-patterns). Sanity-check after: *"did you end up changing the original spec?"*

### 5. One question round at a time, via the tool

When you do ask, use `ask_user_question` with radio/checkbox options and concrete descriptions. Bundle 3-5 closely-related questions per round if they all need to be answered together; never 15. Wait for the round to be answered before the next.

Each question should:
- Have a **title** that names the decision space
- Have a **description** that explains *why this matters* with concrete grounding
- List **3-4 named options** with one-line trade-off descriptions

Multi-axis open-ended forms get rejected as *"too big a question, the interfact breaks with too many options"* (sic). When a form would have that shape, instead propose a plan and let the user ack or push back.

### 6. Scope is the design

Most "what should we build?" questions resolve to "what should we NOT build?". Push hard on:

- **Non-goals** — explicitly out of scope
- **Accepted simplifications** — name the trade-off so the reader knows it's deliberate ("metafield value types stay `String!` — no shop-specific helper in v1")
- **Boundary lines** — what ships in this artifact vs what's consumer-owned vs what the runtime provides
- **YAGNI in TDD framing** — *"don't code for a mechanism we don't use yet. Use TDD philosophy."* Reach for the most common, battle-tested option and minimize deps.

### 7. Quantify before describing

Don't say "many tasks of different kinds." Run the count. For example, to break down Flow's Shopify-tasks registry by `ExecutionType`:
```
rg --no-filename -o "ExecutionType::([A-Z][A-Za-z]+)\.new" -r '$1' \
   lib/flow_core/connector/shopify_tasks/ \
  | sort | uniq -c | sort -rn
```
The `--no-filename` strips the `path:` prefix that would otherwise defeat `uniq -c`; `-r '$1'` emits the captured group, not the whole match. Paste the literal output into the design doc as a row — e.g. "189 tasks → 101 Trigger / 35 Mutation / 29 PrimitiveAction / 23 Fetch / 1 AdminApiOperation" — don't paraphrase the counts. Numbers earn their place in the design doc by being the literal output of a command you actually ran this session.

### 8. Don't paper over reality

- When the code under integration "pushes back" (an error, a constraint, a friction point) — **surface it, don't rationalize it away**.
- When you have a known risk or open question — keep it in the design doc as an "Open questions" or "Known risks" section. Don't bury it.
- When you reach a conclusion under uncertainty — note the uncertainty.
- When a fix is too local — push to prevention layers (type system, existing gem callbacks).

## The phases

### Phase 1 — Understand the system

Read the existing artifacts. Map what exists today. Inventory the data shapes, the call paths, the source-of-truth files. Quantify. Don't propose anything yet. If the user is staring at someone else's PR, read the PR body, follow every link, and figure out what's actually different from last time before walking the diff.

### Phase 2 — Surface the tensions

Now that you understand, name what makes this hard. Are there two superficially-similar artifacts you have to distinguish? Are there competing approaches from other engineers? Is there a known risk you should probe (a BigQuery query against real data, an Observe check, a real-shop dump)?

**Sometimes: prior-art scan.** If the design surface starts to feel like you're reinventing scaffolding, OR the user asks *"is there a tool that does this?"*, do a real prior-art scan: headline verdict, fit-% table per candidate, what overlaps, what doesn't fit, save to `research/<date>-prior-art.md`. Interrogate concretely — *"will it run my manager? will I interact with it the same way?"*. This is rare — only do it when the signal is there, not as a routine step.

### Phase 3 — Iterate on shape

Propose a shape. Get pushback. Refine. Walk findings one at a time, not batched. When you feel uncertain, that's a signal to **read more source**, not to add a caveat. Use the question tool at decision forks. Be willing to reverse the architecture when a concrete failure invalidates the premise — *the plan is a hypothesis, not a contract.*

### Phase 4 — Capture the artifact

Capture the design as a durable artifact. Which artifact, and where it lives, depends on context:

- **New project / SDK / system / feature** → commit `design/<topic>.md` or `spec.md` in the repo, using the structure in `references/design-doc-shape.md`. This is the input to `create-implementation-plan`.
- **Production investigation** → the investigation itself usually serves as the thinking; the public outputs are a GitHub issue comment (risk + evidence) and a PR description (WHAT / WHY / Testing / Review-tip). A `~/.ai/wip/<topic>-<date>.md` may exist as scratchpad but typically isn't shipped as a `design/<topic>.md`. See `examples/investigation-distillation-excerpt.md`.
- **Personal / scratch** → `~/.ai/wip/<topic>-<date>.md` using the same shape.

(Prior-art scans, when triggered in Phase 2, land at `research/<date>-prior-art.md` alongside the design doc.)

## Anti-patterns

See `references/anti-patterns.md` for the long list with quotes. Highlights:

- Proposing before understanding
- Batching findings instead of walking one at a time
- Asking clarifying questions before investigating
- Premature negative conclusions
- Hand-waving caveats when source can answer
- Reimplementing what a library/callback provides
- Trusting one round of adversarial review
- Stopping at "found nothing" without the are-you-sure ladder

## Handoff to create-implementation-plan

When the design is settled — committed design doc, open questions resolved, scope locked — say so explicitly. Suggest the user open a new session and load `create-implementation-plan` against the artifact. The two skills are deliberately separated; the slicer needs a clean head, and `create-implementation-plan` is itself a planner skill, not the implementer (that's `tdd-slice`).

## Examples

- `examples/design-doc-excerpt.md` — what a design doc looks like in practice: "what exists today" inventory table with verdicts, architecture diagram across system boundaries, accepted simplification, Reuse / Do NOT reuse / New trio, open questions
- `examples/investigation-distillation-excerpt.md` — how an investigation gets distilled into an issue comment + PR description
