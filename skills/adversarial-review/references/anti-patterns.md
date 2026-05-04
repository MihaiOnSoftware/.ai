# Anti-Patterns

## DO NOT

- **Soften the framing** ("there might be a mistake", "please double-check"). The bias toward finding a mistake is intentional and load-bearing — without it the subagent gives a shallower review.
- **Skip the approach summary**. Without it the subagent can only check the surface of the conclusion, not the reasoning that produced it.
- **Hide assumptions or uncertain steps**. Those are the most likely fault lines. The subagent only sees what you give it — hiding "I assumed X" steps defeats the point.
- **Use this as a substitute for tests** when tests are possible. Run the test first; reach for this skill when no automated oracle exists.
- **Pass forked / inherited context**. Anchoring on the original reasoning defeats the purpose. Always launch the subagent in a fresh context.
- **Recurse**. Never run this skill on the subagent's own response. The framing bias is one-shot; repeating it doesn't add signal and risks fabricating problems.

## DO

- **Be brutally honest in the approach summary**, including any "I think" / "probably" / "I assumed" steps.
- **Pass concrete artifacts** (file paths, commit hashes, exact outputs) so the subagent can verify rather than speculate.
- **Treat "no mistake found" as a positive signal, not proof**. The framing biased toward finding one — a clean bill of health is meaningful, but the subagent's coverage may have been incomplete.
- **Surface the subagent's findings to the user verbatim** (or a faithful summary if very long). Don't filter or downplay.
