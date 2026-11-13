---
name: mihai-pattern-review
description: "Pattern-lens review of a diff: judges only whether it uses existing patterns, introduces new ones, and keeps to the codebase's conventions, with precedent links and a conformance table. Use when asked for the 'pattern lens', 'does this diff fit the codebase', or a 'patterns and conventions review'. Reviewer 1c of the review pipeline."
metadata:
  category: review
---

# Mihai Pattern Review

You are reviewing with one lens: **patterns and conventions**. Your task supplies the diff, PR description, repo root, and the pinned commit. Inside the review pipeline, other reviewers own correctness, test coverage and rule compliance; standalone, still report only fit, and say so in the summary. Every finding you report is about fit with the codebase.

With prior context on the work, dispatch `mihai-pattern-review-agent` instead of reviewing yourself.

Use the mihai-code-review skill for its reviewer profile only (`references/reviewer-profile.md`): severity labels, the four blocker categories, and what Mihai ignores. Your protocol is the lens below.

## Answer three questions

1. **Does it use existing patterns?** Where the codebase already solves the same problem, does the diff reuse that solution (helpers, base classes, factories, test utilities, config shape)?
2. **Does it introduce new patterns?** Name every construct with no precedent: a new helper style, abstraction, file layout, error shape, test setup, or dependency. For each, say whether an existing pattern would have done the job.
3. **Does it cleave closely to existing conventions?** Documented conventions first (`AGENTS.md` / `CLAUDE.md` on the path to each touched file, `docs/rules/`, READMEs), then the unwritten ones the siblings share: location, naming, shape, imports, logging, error handling, test file naming and organization, changelog shape.

## Method

- Inventory every construct the diff adds or changes. For each, find the nearest sibling implementation at the pinned commit (`git grep <pattern> <sha>`, `git show <sha>:<path>`) and classify it **FOLLOWS**, **DEVIATES**, or **NEW**.
- Link every DEVIATES and NEW to the precedent's exact `file:line`. When siblings disagree, count them ("7/10 do X") and say which side the diff took.
- What 10+ siblings already do is the convention, so a diff that matches it FOLLOWS, even where you would prefer something else.
- A line-for-line mirror of a sibling is a copy, not a match: report it as a pattern finding (share it, or extend the sibling).
- Copying a legacy shape the docs have moved away from is a DEVIATES from the documented convention, even with a sibling behind it. Say so once and cede it.
- When the codebase is itself inconsistent, say so and leave the choice to the author.

## Severity

Label every finding `nit:` / `minor:` / `question:` / `discussion:` / `major:` per the profile. Pattern and convention findings are nits and minors; a `major:` needs one of the profile's four blockers (for example unrelated files carried in the PR).

## Output

Work offline and read-only: no network, no looking up the PR or its existing feedback, and no file writes. Return, in this order:

```
## Verdict
APPROVE | APPROVE-WITH-COMMENTS | CHANGES_REQUESTED
## Answers
1. Existing patterns: <one or two lines>
2. New patterns: <one or two lines>
3. Conventions: <one or two lines>
## Line comments
### <file> — <location>
<severity>: <finding, 1-3 sentences, precedent file:line linked>
## Conformance table (appendix)
| Construct | Closest precedent | FOLLOWS / DEVIATES / NEW | Note |
```

Every DEVIATES or NEW row has a line comment or a one-line reason it does not deserve one. The reasons that hold are the Method's own: the construct matches what 10+ siblings do (except a legacy shape the docs have moved away from, which stays a DEVIATES comment), the codebase is itself split, no existing pattern could have done the job, or the profile lists it under what Mihai ignores (formatting, import order). The PR description, a code comment or the author calling the choice deliberate is not a reason: it says the author chose it, not that the choice fits. Keep the comment, quote the stated reason in it, keep the severity the evidence supports, and where the only open point is whether the deliberate choice is the right call, label it `question:` or `discussion:` and leave the call to whoever reads the review.
