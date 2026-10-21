---
name: shape-review-comments
description: Shapes raw review findings into postable file:line comments written in Mihai's voice. Use when you have findings from an adversarial-review-loop or mihai-code-review run and need to decide what to post, what to drop, and how to phrase what survives.
license: MIT
---

Takes raw review findings and produces postable comments: triage what to skip, frame what survives in Mihai's voice at the right file:line, verify line numbers, then present for approval.

Reference files (load both before writing a single comment):
- [references/triage-rules.md](references/triage-rules.md) — what to drop, what to keep, severity labels
- [references/voice-guide.md](references/voice-guide.md) — sentence structure, hedges, closers, worked examples

If either reference file cannot be read, stop and report it — do not attempt to triage or write comments from memory.

If the findings list is empty, tell the user and stop.

## Step 1 — Load the references

Read both reference files completely before proceeding.

## Step 2 — Triage

For every finding, assign one of:
- **Post** — survives, worth saying
- **Drop** — not worth saying; note the reason briefly so it isn't reconsidered
- **Merge** — combine with a closely related finding on the same line or function

Apply triage rules before writing any comment text. Do not let wording decisions influence whether a finding survives.

Produce a visible triage log (one line per finding: decision + brief reason) before moving to Step 3. This lets the user catch wrong drops before comments are written.

## Step 3 — Write the comments

For each surviving finding, write the comment following the voice guide (anchor line selection, hedges, closers, severity labeling are covered there).

After writing each comment, scan it for em-dashes within the text and replace them with commas or sentence breaks before moving on.

Output format:

```
`path/to/file.ts:LINE` — severity: comment text
```

## Step 4 — Verify line numbers

Before presenting to the user, confirm each line number at current HEAD. Run `grep -n` for the anchoring expression in the file. If the file has changed since the review and a finding was already fixed, drop that comment and note it.

If a line number cannot be confirmed (file deleted, path changed), drop the comment and tell the user.

## Step 5 — Present for approval

Present the shaped comments to the user. Walk through them one at a time if there are many, or offer to batch them if they are straightforward.

If the user rejects all comments, ask whether to re-triage from scratch with different criteria or to close. Do not loop silently.
