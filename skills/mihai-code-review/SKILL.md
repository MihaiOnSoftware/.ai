---
name: mihai-code-review
description: "Review a PR, branch, or diff the way Mihai would: mechanical style/test sweeps first, then precedent diffing, then an adversarial correctness hunt. Use when asked to 'review like Mihai', 'mihai review' a PR/diff, or to apply the Mihai reviewer profile inside an adversarial review loop."
license: MIT
metadata:
  category: review
---

# Mihai Code Review

Review code the way Mihai reviews it. The protocol exists because a plain adversarial "find the mistake" framing biases reviewers toward correctness defects and silently drops the other half of Mihai's feedback: mechanical style sweeps, test-quality checks, comments-that-should-be-code, and precedent alignment. The fix is structural, not motivational — **the sweeps run first and produce a mandatory log; the adversarial hunt runs last.**

The full reviewer profile (tone, severity framework, categories, what he ignores) is at [references/reviewer-profile.md](references/reviewer-profile.md). Read it before reviewing. The sweep checklists are at [references/sweeps.md](references/sweeps.md).

## When to Use This

- The user asks to review a PR/branch/diff "like Mihai" or invokes the reviewer profile
- An adversarial-review-loop iteration targets code changes and should carry Mihai's review dimensions, not just correctness
- You need a second-opinion code review whose output should look like a real teammate's review (severity labels, nits ceded to the author, precedent links)

Not for reviewing design docs or plans — use `adversarial-review` / `adversarial-review-loop` directly for those.

## Running It

Two modes:

1. **You are the fresh reviewer** (dispatched into a clean context, or the user handed you a diff directly): follow the protocol below yourself.
2. **You have prior context on the work** (you wrote it, or your session reasoned about it): do NOT review it yourself. Spawn a fresh-context subagent with the prompt template at [references/subagent-prompt.md](references/subagent-prompt.md) — same rule as `adversarial-review`, and for the same reason: a reviewer anchored on the author's reasoning misses what the author missed. If your harness has a purpose-built reviewer agent, use it.

Either way, the reviewer needs: the diff (at the commit under review, not a drifted working tree), the PR description, and read access to the repo for precedent lookups and coverage checks.

## Protocol — three passes, in this order

The order is load-bearing. Sweeps are cheap and bounded; the hunt is open-ended. Run the open-ended pass last so it cannot consume the budget of the bounded ones.

### Pass 1 — Mechanical sweeps (bounded, checklist-driven)

Run every checklist in [references/sweeps.md](references/sweeps.md):

- **Per-function sweep** over every new or moved function: guard-clause shape, type-impossible checks, branch test coverage, complex inline expressions, helpers-wanting-their-own-file, duplicated literals.
- **Per-test-file sweep** over every test file touched: `should … when …` naming, vacuous assertions, can-this-spec's-code-fail-it, low-value tests, superseded integration specs in extraction PRs.
- **Comment sweep** over every comment in the diff: function-trying-to-manifest, repeats-the-code, stale-prone references, better-as-test, better-as-commit-message.
- **Leftovers/metadata sweep**: orphaned config/deps/mocks, changelog honesty, migration filename accuracy, scope hygiene (unrelated files).

**Output requirement: a sweep log.** Before writing any review comment, record every checklist item with either findings or `clean`. The log is what prevents this pass from being skipped — an empty-findings sweep still produces log lines. Keep the log; it goes in your working notes, not the final review.

### Pass 2 — Precedent diff (bounded)

For anything the PR introduces that the codebase already has a pattern for — config, producers/consumers, UI components, schema fields, test setups — find the **nearest sibling implementation** (`git grep` at the review commit) and diff the new code against it point by point: file/module location, shape, naming, props/patterns of sibling components, env vars, logging, test utilities. Link each divergence to the precedent's exact file/line. Acknowledge when the codebase itself is inconsistent; don't die on that hill.

### Pass 3 — Adversarial hunt (open-ended)

Now hunt correctness defects with the adversarial framing: assume there is a defect in the diff and find it. Focus where Mihai's blockers live: missing or insubstantial tests for new behavior, spec/runtime/docs disagreement, correctness and security holes, cross-cutting data assumptions (org boundaries, multi-location, soft-delete semantics), subtle semantic changes smuggled into refactors.

### Compose the review

Merge all three passes, then apply the profile:

- Severity-label every finding (`nit:` / `minor:` / `major:` / `question:` / `discussion:`) per the profile's framework. Block **only** on the four blocker categories.
- Write in Mihai's voice: 1–3 sentences per comment, question-form, hedged where uncertain, nits explicitly ceded to the author, precedent linked.
- One- or two-line review summary stating the verdict and the theme of the comments.
- Verdict: APPROVE / APPROVE-WITH-COMMENTS / CHANGES_REQUESTED.

## Output

The final review contains: verdict, summary body, line comments grouped by file. Do not include the sweep log in the review itself — but if the dispatching agent asks for it (e.g. a validation harness), return it as an appendix.

## Anti-Patterns

- **Running the hunt first.** It eats the budget and the sweeps degrade into an afterthought — exactly the failure this skill exists to prevent.
- **Skipping sweep items that "obviously don't apply".** The log forces the decision to be explicit; `clean` is a valid answer, silence is not.
- **Softening blockers.** A new code path with no meaningful test is CHANGES_REQUESTED, not a `minor:` — see the profile's blocker list.
- **Inflating severity.** Style and structure findings are never blockers on their own, no matter how many the sweeps produce.
- **Reviewing with inherited context.** If you touched the work, spawn the fresh reviewer (mode 2). No exceptions for "small" diffs.
- **Padding.** If a pass finds nothing, the review gets shorter, not noisier. Mihai writes "Not even a nit again lol" when it's clean.
