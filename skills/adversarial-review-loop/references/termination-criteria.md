# Termination Criteria

The loop stops when the next round of feedback stops adding signal. Pick the first condition that fires. Do **not** keep looping hoping for one more useful finding — diminishing returns are the signal to stop.

## 1. Weak

**Condition**: This iteration produced zero Accepts. Every finding was Reject (invalid), Reject (weak), or Repeat.

**Why it terminates**: The subagent is now nitpicking or recycling. No fix was applied this round, so the next round would be reviewing the same artifact — guaranteed to produce more of the same.

**Example**: Iteration 3 produces three findings: one Reject (weak) about variable naming, one Reject (invalid) citing a function that doesn't exist, one Repeat of iteration 2's already-fixed issue. → Stop.

## 2. Repeated

**Condition**: Two consecutive iterations produced no **new** accepted findings. ("New" = not a repeat of a prior accepted finding.)

**Why it terminates**: One round of weak findings could be a fluke; two in a row means the well is dry. This catches the case where a single iteration squeezes out one minor Accept and you'd otherwise loop forever waiting for another zero-Accept round.

**Example**: Iteration 4 accepts one minor fix (rename a confusing variable). Iteration 5 produces only Rejects and Repeats. → Stop. Even though iteration 4 had an Accept, iteration 5 confirms the loop has converged.

## 3. Invalid

**Condition**: Every finding this iteration was Reject (invalid) — the subagent is fabricating problems (citing nonexistent code, contradicted by the artifact, etc.).

**Why it terminates**: The framing bias has tipped over into hallucination. Continuing wastes tokens and risks you accepting a fabricated finding out of fatigue.

**Example**: Iteration 2 produces two findings, both citing functions that don't exist in the codebase. → Stop.

## 4. Hard Cap (5 iterations)

**Condition**: You have completed 5 iterations without any of the above firing.

**Why it terminates**: Either the work is genuinely too complex for this skill (consider breaking it up), or the loop is oscillating (subagent keeps finding new-looking issues, you keep accepting marginal fixes). Either way, hand the decision back to the user — keep going, ship it, or restructure.

**When you hit the cap, flag it explicitly**: "Hit the 5-iteration cap without natural termination. Iterations 1–5 each produced at least one Accept. The loop may not be converging. Recommend: [your judgment]."

## What Does NOT Terminate the Loop

- **A single iteration with only one Accept**. One small fix is still signal. Keep going (subject to condition 2).
- **Subjective fatigue**. "I'm tired of this" is not a termination criterion. Use the rules.
- **The subagent saying "I cannot find a mistake"**. That's a strong signal but treat it as one input to condition 1 (weak). If the subagent finds nothing, that iteration has zero Accepts → condition 1 fires → terminate. (Same outcome, but reach it through the rule, not the subagent's self-report.)

## Recording the Termination Reason

In the final summary, state which condition fired and the evidence:

> **Terminated**: Condition 1 (weak). Iteration 4 produced 2 findings, both Reject (weak) — speculative concerns about edge cases with no evidence the scenarios apply. Zero Accepts.

This lets the user audit whether you stopped too early or too late.
