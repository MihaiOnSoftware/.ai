# Anti-Patterns

The `adversarial-review` skill's anti-patterns all still apply per iteration — they come along when you load that skill (which this loop requires). The ones below are loop-specific.

## DO NOT

- **Reuse subagent context across iterations.** Every iteration spawns a brand-new fresh-context subagent. If you carry context forward, the new subagent anchors on prior findings and stops being adversarial.
- **Tell the subagent about prior iterations or prior findings.** It must come in blind. The whole point is an independent look at the *current* state.
- **Run the review on the previous subagent's report.** That's the recursion the parent skill forbids and it doesn't become OK inside a loop. You always review the **work**, not the **review**.
- **Accept findings to keep the loop feeling productive.** If a round produces only weak / invalid / repeat findings, that's the termination signal — honor it, don't manufacture an Accept to justify another round.
- **Reject findings to make the loop terminate.** The opposite failure mode. If a finding is genuinely valid, Accept it and continue. Do not downgrade Accepts to Rejects to hit a termination condition.
- **Loop past the hard cap.** Five iterations is the cap. If you hit it, hand the decision back to the user with your honest assessment — do not silently keep going.
- **Skip the per-iteration log.** Without it the user can't audit your triage and the value of the loop collapses to "I ran some reviews, trust me".
- **Hide rounds where you rejected everything.** Those rounds are the most informative — they're the evidence that termination was earned, not assumed.
- **Forget to update the approach summary between iterations.** Each new subagent needs to know what changed since the original work, otherwise it'll re-flag already-fixed issues (which then look like Repeats and prematurely terminate the loop).
- **Apply Defer items.** They're explicitly out of scope. Surface them; don't expand the task.

## DO

- **Be ruthless in triage.** The loop's value is in the rejection rate as much as the acceptance rate. A good loop rejects most findings and accepts a few high-impact ones.
- **Verify before accepting.** Re-read the file, re-run the test, re-derive the result. The subagent's claim is a hypothesis, not a fact.
- **Note contradicting evidence on every Reject (invalid).** "Subagent claimed X but file Y says W" — this protects future-you from second-guessing and gives the user something to audit.
- **Track repeats explicitly.** Cross-reference each finding against the previous-findings list. Repeats are a strong, principled termination signal — don't waste them by missing them.
- **Update the approach addendum each iteration.** A short "since the original: fixed X in iteration 1, fixed Y in iteration 2, rejected Z because..." keeps the next subagent oriented.
- **State the termination reason explicitly** with the evidence that triggered it. "Stopped after iteration 4: zero Accepts, two Rejects (weak), one Repeat of iteration 2's finding."
- **Trust convergence.** When the loop terminates, the work has survived multiple independent adversarial looks. That's a real signal — don't undermine it by adding "but maybe I should run one more...".
