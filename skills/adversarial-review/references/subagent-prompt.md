# Subagent Prompt Template

Use this prompt verbatim when launching the subagent in Step 2. Substitute only the bracketed sections — leave everything else as-is. The framing is load-bearing.

```
Another agent just finished a task and reached this conclusion:

[CONCLUSION / END STATE]

Here is a summary of the approach they took:

[APPROACH SUMMARY]

There is a mistake somewhere in their work. The conclusion is wrong,
but the original agent doesn't know it. Your job is to find the
mistake(s) and explain how they affected the conclusion / end state.

Investigate carefully. Re-derive key results, re-read referenced
files, check assumptions, run anything that can be checked. Do not
take any step in the approach for granted.

Return your findings inline as a markdown response with these
sections:

1. **Mistakes found** — the specific mistake(s), with evidence (file
   paths, line numbers, quoted text, or contradicting reasoning).
2. **Impact** — how each mistake affected the conclusion / end state.
3. **Corrected conclusion** — what the conclusion / end state should
   be once the mistakes are accounted for.
4. **If you genuinely cannot find a mistake** after thorough
   investigation, say so explicitly and list the avenues you checked
   so the original agent can judge how much coverage you had.

Do not write any files. Return the findings directly in your
response.
```

## What to Substitute

- **`[CONCLUSION / END STATE]`** — the exact answer, output, or final state. Quote it, paste the snippet, or describe the file changes (paths + summary). No paraphrasing into vagueness.
- **`[APPROACH SUMMARY]`** — short narrative of the steps, decisions, assumptions, and sources used. Include any "I think" / "probably" / "I assumed" steps verbatim.

## What NOT to Change

- The opening "Another agent just finished a task..." framing
- The assertion "There is a mistake somewhere... the conclusion is wrong, but the original agent doesn't know it"
- The investigation instructions
- The output structure (sections 1–4)
- The "Do not write any files" line

Softening any of these — e.g. "there might be a mistake", "please double-check" — defeats the bias the skill depends on.
