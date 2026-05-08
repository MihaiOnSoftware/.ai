# Triage Rubric

Every finding from each iteration's subagent must land in exactly one bucket. Be honest — the loop's value depends on rejecting noise as readily as accepting signal.

## Accept

Apply the fix. Use this bucket only when **all** of:

- The finding identifies a concrete defect (wrong logic, wrong fact, missing case, broken reference, contradicted assumption).
- The defect materially affects correctness, the conclusion, or downstream decisions.
- You can verify the defect against evidence — file contents, command output, the artifact itself — not just the subagent's word.

If you cannot verify it, do not Accept on faith. Either verify, or move it to Reject (weak) with a note that you couldn't confirm it.

## Reject (invalid)

The finding is wrong. Use when:

- It cites a file, line, function, or fact that doesn't exist or doesn't say what the subagent claims.
- It's contradicted by the actual artifact or by a quick check (run the test, re-read the file, re-derive the math).
- It rests on an assumption you can show is false.

**Always note the contradicting evidence** in the log entry. "Subagent claimed X but file Y line Z actually says W."

## Reject (weak)

The finding is plausible but not worth acting on. Use when:

- It's stylistic, taste-based, or bikeshedding (naming, formatting, "could be clearer").
- It's speculative ("this might break if...") with no evidence the scenario applies.
- The impact is negligible relative to the work's purpose.
- It's a generic concern ("consider adding more tests") with no specific defect attached.

Note the reason. Don't accept weak findings just to keep the loop feeling productive.

## Repeat

The finding is substantively the same as one from a prior iteration, regardless of how that prior one was triaged. Use when:

- Same defect, same location — even if phrased differently.
- Same class of concern about the same artifact (e.g. "this function is too long" appearing in iteration 1 and again in iteration 3).
- A previously-Accepted finding is being raised again because the subagent didn't realize it was already fixed (which can happen if your approach addendum was unclear).

Note which prior iteration's finding it repeats. Repeats are a strong termination signal.

## Defer

The finding is valid but out of scope. Use when:

- It's a real issue but in a different system / file / concern than the work under review.
- It would expand the task beyond what the user asked for.
- It's a follow-up worth tracking but not blocking the current conclusion.

Surface deferred items explicitly in the final summary so the user can choose to act on them.

## Tie-breakers

- **Accept vs Reject (weak)**: If you're unsure, ask "would I be embarrassed if a careful reviewer pointed this out later?" Yes → Accept. No → Reject (weak).
- **Reject (invalid) vs Reject (weak)**: Invalid means demonstrably wrong. Weak means plausible but not worth it. When in doubt, Reject (weak) is safer (it doesn't accuse the subagent of being wrong without proof).
- **Repeat vs Accept**: If a prior iteration rejected this and the new iteration raises it again with **new** evidence, treat it as a fresh Accept candidate, not a Repeat. Note the new evidence.
