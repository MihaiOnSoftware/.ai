---
name: adversarial-review-loop
description: Iterate adversarial-review until feedback dries up — run a fresh-context adversarial subagent, incorporate the valid findings, run again on the updated work, repeat until findings are weak, repeated, or invalid. Use when stakes justify several passes and a single review isn't enough.
license: MIT
metadata:
  category: review
---

A controlled loop around the `adversarial-review` skill. Each iteration spawns a **new** fresh-context subagent against the **updated** work (not against the previous subagent's report — that would be the recursion the parent skill forbids). The loop terminates when the next round of feedback no longer adds signal.

**Prerequisite**: Load the `adversarial-review` skill before using this one — this skill delegates the per-iteration mechanics (subagent prompt, fresh-context requirement, framing rules) to it. If you haven't loaded it, load it now.

## When to Use This

**User-triggered**: The user explicitly asks for an adversarial review *loop*, or asks you to "keep reviewing until it's clean / nothing new comes up".

**LLM-triggered**: Reach for this on your own, **before declaring a task done**, when *all* of these hold:

- The conditions for `adversarial-review` are met (no automated oracle, high stakes).
- The work is substantial enough that one pass plausibly misses things — e.g. a multi-file refactor, a research conclusion that other decisions hang on, an architectural design doc, a long proof or derivation.
- Each round of fixes meaningfully changes the artifact, so a fresh adversarial pass on the *updated* version isn't redundant.

If a single `adversarial-review` would suffice, use that instead. The loop costs more tokens and time; only spend them when one pass is likely to leave material issues on the table.

## What This Skill Does

**Input**: None directly — uses your current session state (the work you've completed).

**Output**: A final summary to the user containing:
- The final conclusion / end state after all incorporated fixes
- A per-iteration log: what the subagent found, what you accepted, what you rejected and why, what changed
- The termination reason (weak / repeated / invalid feedback) with evidence

**Does**:
- Run `adversarial-review` repeatedly, each time against the **current** state of the work
- Triage each round's findings into accept / reject / defer with explicit reasoning
- Apply accepted fixes, then re-run with a **new** fresh-context subagent
- Stop on a principled termination condition, not after a fixed number of rounds
- Log the journey so the user can audit it

**Does NOT**:
- Apply rejected feedback "just to be safe"
- Loop forever — there is a hard cap (see Termination)
- Reuse subagent context between rounds — every round is fresh
- Run a review on the previous subagent's *report* (that's the recursion the parent skill forbids)

## Workflow

### Step 1: Set Up the Loop

Before iteration 1, capture and freeze:

1. **Original conclusion / end state** (same definition as `adversarial-review` Step 1).
2. **Original approach summary** (same definition as `adversarial-review` Step 1).
3. **A running log** with one entry per iteration (initially empty).
4. **A previous-findings list** (initially empty) — used to detect repeats.

Put the original conclusion + approach in your response so the trail is auditable.

### Step 2: Run One Iteration

For each iteration `N` (starting at 1):

1. **Run one pass of the `adversarial-review` skill** (which you should already have loaded — see Prerequisite). It owns the subagent prompt, the fresh-context requirement, and the framing rules; do not re-implement them here. Substitute its prompt template with:
   - `[CONCLUSION / END STATE]` → the **current** end state (not the original — incorporate everything accepted in iterations 1..N-1).
   - `[APPROACH SUMMARY]` → the original approach **plus** a short addendum listing the changes made in iterations 1..N-1 and why.

   Do **not** mention prior subagents or prior findings. Each subagent starts blind.

2. **Triage the findings** using [references/triage-rubric.md](references/triage-rubric.md). For each finding, classify it as:
   - **Accept** — valid, materially affects the conclusion or correctness. Apply the fix.
   - **Reject (invalid)** — based on a misreading, a hallucinated file/line, a wrong assumption, or contradicted by evidence. Note the contradicting evidence.
   - **Reject (weak)** — technically possible but speculative, low-impact, or stylistic. Note the reason.
   - **Repeat** — substantively the same as a finding from a prior iteration (whether previously accepted *or* rejected). Note which prior finding it repeats.
   - **Defer** — valid but out of scope for this work. Note explicitly so the user sees it.

3. **Append a log entry** with: iteration number, finding-by-finding triage, fixes applied (file paths + summary), and updated end state.

4. **Update the previous-findings list** with this iteration's findings (so the next round can detect repeats).

### Step 3: Check Termination

Stop the loop when **any** of these holds (see [references/termination-criteria.md](references/termination-criteria.md) for details and examples):

- **Weak**: Every finding this iteration was Reject (weak), Reject (invalid), or Repeat. No Accepts.
- **Repeated**: Two consecutive iterations produced no new accepted findings (covers the case where iteration N had one weak Accept but iteration N+1 had nothing).
- **Invalid**: Every finding this iteration was Reject (invalid) — the subagent is now fabricating problems.
- **Hard cap**: You have completed **5 iterations**. Stop regardless and flag this explicitly to the user — hitting the cap means either the work is genuinely complex or the loop isn't converging, and the user should decide.

If none of these holds, go to Step 2 for iteration `N+1`.

### Step 4: Surface the Result

Return to the user:

1. **Final end state** — the conclusion / artifact after all accepted fixes.
2. **Termination reason** — which condition above tripped, with the evidence (e.g. "iteration 3 had 2 Reject (weak) and 1 Repeat, no Accepts").
3. **Iteration log** — full per-round triage and fixes. Faithful summary if very long, with full text available on request.
4. **Deferred items** — anything classified Defer, surfaced explicitly so the user can decide follow-up.
5. **Your own short take** — confidence in the final state, anything that still nags you, recommended next action.

Do **not** silently apply rejected fixes. Do **not** hide rounds where you rejected everything — those are the most informative.

## Anti-Patterns

See `references/anti-patterns.md` for the full DO / DO NOT list. The `adversarial-review` skill's own anti-patterns also apply per iteration — they come along when you load that skill (which this loop requires).
