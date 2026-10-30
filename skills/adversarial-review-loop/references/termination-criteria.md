# Termination Criteria

The loop stops when the next round of feedback stops adding signal. Pick the first condition that fires. Do **not** keep looping hoping for one more useful finding — diminishing returns are the signal to stop.

## 1. Weak

**Condition**: This iteration produced zero Accepts. Every finding was Reject (invalid), Reject (weak), or Repeat.

**Why it terminates**: The subagent is now nitpicking or recycling. No fix was applied this round, so the next round would be reviewing the same artifact — guaranteed to produce more of the same.

**Example**: Iteration 3 produces three findings: one Reject (weak) about variable naming, one Reject (invalid) citing a function that doesn't exist, one Repeat of iteration 2's already-fixed issue. → Stop.

## 2. Invalid

**Condition**: Every finding this iteration was Reject (invalid) — the subagent is fabricating problems (citing nonexistent code, contradicted by the artifact, etc.).

**Why it terminates**: The framing bias has tipped over into hallucination. Continuing wastes tokens and risks you accepting a fabricated finding out of fatigue.

**Example**: Iteration 2 produces two findings, both citing functions that don't exist in the codebase. → Stop.

## 3. Hard cap — iteration 5 always stops (converged or escalate)

**Condition**: Iteration 5 is an absolute ceiling. After its triage it stops unconditionally, regardless of conditions 1–2 (Weak, Invalid), and a 6th iteration is never started. The outcome is decided from round 5 alone. Every round-5 outcome maps to exactly one of the two outcomes below; the split turns on whether round 5 produced a substantive new Accept (see "What substantive means" below).

**Why the cap is absolute**: Five rounds is the budget. Without an unconditional stop, a round that matches no other condition (for example, Defer-only or minor-Accept-only) would roll into a 6th iteration.

### Converged — round 5 produced no substantive new Accepts

Covers: zero Accepts; only Reject / Repeat / Defer findings in any mix; or only non-substantive Accepts (minor, stylistic).

**Action**: Apply the held iteration-5 fixes (the non-substantive ones). Flag to the user that the cap (5 iterations) was hit but the loop converged. Surface any Deferred items. Report normally.

**Examples**:
- Iteration 5 produces one Reject (weak) and two Repeats. → Stop, flag cap, report converged. Nothing is held, because the round produced no Accepts.
- Iteration 5 produces one Defer only (valid, out of scope). → Stop, flag cap, report converged, surface the Defer.
- Iteration 5 produces one minor Accept (stylistic wording in a heading). → Apply the held fix, flag cap, report converged.

### Escalate — round 5 produced at least one substantive new Accept

**Why this is different**: Five rounds without convergence indicates a deep design flaw or a genuinely hard tradeoff requiring human judgment. Continuing to loop is wasteful and masks the real problem.

**Action**: Stop the loop immediately. Do **not** apply the 5th iteration's fixes (SKILL.md Step 2 held them for this check) and do not start a 6th round. Instead, escalate:

- **Running as a subagent** (invoked by `solve-this-problem` or another parent agent): emit a `NEED_HUMAN:` message to the parent. List the unresolved findings from iteration 5 clearly. The parent must pause and wait for human intervention before continuing the pipeline.
- **Running interactively** (direct user conversation): surface the unresolved findings directly to the user. Ask for explicit guidance — do not proceed until the user responds.

**Example**: Iteration 5 produces two Accepts: a logic error in the retry path and an unhandled race condition. → Stop, escalate with `NEED_HUMAN:` (or surface directly), list those two findings.

**What “substantive” means**: A finding is substantive if it is (a) new — not a repeat of an already-addressed point, (b) non-trivial — not a style preference or speculative edge case, and (c) affects correctness, safety, or the conclusion.

## What Does NOT Terminate the Loop

- **A single iteration with only one Accept**. One small fix is still signal. Keep going (before iteration 5; at iteration 5 the hard cap stops the loop regardless). If the next iteration produces zero Accepts, condition 1 fires.
- **Subjective fatigue**. "I'm tired of this" is not a termination criterion. Use the rules.
- **The subagent saying "I cannot find a mistake"**. That's a strong signal but treat it as one input to condition 1 (weak). If the subagent finds nothing, that iteration has zero Accepts → condition 1 fires → terminate. (Same outcome, but reach it through the rule, not the subagent's self-report.)

## Recording the Termination Reason

In the final summary, state which condition fired and the evidence:

> **Terminated**: Condition 1 (weak). Iteration 4 produced 2 findings, both Reject (weak) — speculative concerns about edge cases with no evidence the scenarios apply. Zero Accepts.

This lets the user audit whether you stopped too early or too late.
