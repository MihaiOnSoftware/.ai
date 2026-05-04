---
name: adversarial-review
description: Spawn a fresh-context subagent that is told a mistake exists in your work and tasked with finding it. Useful as a self-check after reaching a conclusion or end state when no automated oracle is available.
license: MIT
metadata:
  category: review
---

Spawn a subagent with an intentionally biased prompt: it is told the conclusion is wrong and its job is to find the mistake. The adversarial framing forces a harder look than a neutral "review my work" prompt.

## When to Use This

**User-triggered**: Whenever the user asks for an adversarial or second-opinion check on completed work.

**LLM-triggered**: Reach for this on your own, **before declaring a task done**, when *both* of these hold:

- The conclusion isn't independently verifiable (no test, no oracle, no ground truth to compare against)
- Stakes are high enough to warrant a second pass (production code, irreversible action, user is relying on the result, research conclusion that will be acted on)

If a test or other automated check is available, run that first. This skill exists for the cases where automation can't verify the result.

## What This Skill Does

**Input**: None directly — uses your current session state.

**Output**: The subagent's findings, returned inline. Either:
- The mistake(s) found and how they affected the conclusion / end state
- "I cannot find a mistake" plus the avenues investigated (treat with care — the framing biases toward finding one, so a clean bill of health is meaningful)

**Does**:
- Capture your conclusion / end state
- Summarize the approach you took to reach it
- Spawn a **fresh-context** subagent with adversarial framing
- Surface the subagent's findings to the user

**Does NOT**:
- Apply fixes silently — the user decides the next step
- Soften the framing — the prompt asserts a mistake exists on purpose
- Recurse — never run this skill on the subagent's own report (see Anti-Patterns)

## Workflow

### Step 1: Capture the End State

Write down, plainly, in your own response so it's auditable:

1. **Conclusion / end state**: The exact answer, output, or final state you arrived at. Be specific — quote it, paste the relevant snippet, or describe the resulting file changes (paths + summary). No paraphrasing into vagueness.

2. **Approach summary**: A short narrative of how you got there. Cover:
   - The problem as you understood it
   - The key steps or decisions
   - Assumptions you made
   - Tools, files, or sources you relied on

Be brutally honest. Include any "I think" / "probably" / "I assumed" steps. The subagent only sees what you give it — hiding uncertain steps defeats the point.

### Step 2: Launch the Subagent

Spawn a subagent **in a fresh context** — no inherited session history, only the prompt you provide. Use whichever subagent / Task mechanism your harness offers (Claude Code's Task tool, OpenCode's subagent invocation, pi's `subagent` tool, etc.). The fresh context is required: it prevents the subagent from anchoring on the original reasoning.

For the prompt template (use verbatim, substituting only the bracketed sections), see [references/subagent-prompt.md](references/subagent-prompt.md).

### Step 3: Surface the Result

Relay the subagent's findings to the user. Include:

- The subagent's response in full (or a faithful summary if it's long, with the full text available on request)
- Your own short take: whether mistakes were found, severity (does the conclusion change?), and a recommended next action — fix now / investigate further / accept and move on

Do **not** silently apply fixes. Let the user decide.

## Anti-Patterns

See [references/anti-patterns.md](references/anti-patterns.md) for the full DO / DO NOT list.
