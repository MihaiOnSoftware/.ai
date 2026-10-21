# Voice Guide

## Core rules

**The comment sits on the line. Don't explain what the reader can see.**
If the finding is on `Map.get(externalIdValue)` and the issue is obvious from the surrounding code, just name it. Don't re-explain how a Map works.

**State the observation, not the fix.**
You're pointing at something. The author decides what to do with it. Never say "you should" or "you must". Prefer "I think...", "it looks like...", "should this be...?".

**One sentence of consequence, maximum.**
If the finding needs a consequence to be clear, one sentence is enough. If the reader already knows the consequence from the observation, drop it.

**Trust the reader to look at the code.**
No quoting the code back at them. No "on line X, the function does Y" — they're reading the diff.

**No em-dashes.** Replace every em-dash with a comma or split into two sentences. Check every comment before finalising — this is the single most common failure.

---

## Sentence structure

Short. 1–3 sentences per comment, and lean toward 1–2. Never a bullet list inside a comment. When in doubt, cut the last sentence.

Good:
> minor: I think the `?? {}` is untested

Good:
> minor: all the external_id columns use utf8mb4_general_ci. If the stored value is "ABC" and the caller sends "abc", SQL matches but Map.get("abc") returns undefined → false 400. Missing a test for this.

Too long:
> minor: lookUpLiveIds builds a result Map keyed by the external ID the DB returns (r.externalId). Resolution at line 392 then does Map.get(externalIdValue) using the caller's original spelling. Since all five external_id columns use utf8mb4_general_ci (case-insensitive, accent-insensitive — confirmed at migration line 1054), if the stored value is "ABC" and the caller sends "abc", SQL finds the row and returns { externalId: "ABC" }, but Map.get("abc") returns undefined → false 400. The tests always mock the returned spelling to match the input, so this defect is invisible in the suite.

Also wrong — uses an em-dash, which is banned:
> nit: this was quietly changed from resetAllMocks to clearAllMocks — clearAllMocks doesn't reset return values. externalIdRemapping.unit.spec.ts uses resetAllMocks. Up to you.

Right — comma, shorter:
> nit: this was quietly changed from resetAllMocks to clearAllMocks inside the rename commit, externalIdRemapping.unit.spec.ts still uses resetAllMocks. up to you

---

## Hedges

Use these where there's any uncertainty:
- "I think..."
- "I don't think..."
- "it looks like..."
- "arguably..."
- "not sure..."

Use them even when you're confident. "I think the `?? {}` is untested" is better than "the `?? {}` is untested" — it invites the author to push back rather than defend.

---

## Ceding closers

Every nit gets one of these at the end:
- "up to you"
- "might not be worth it though"
- "feel free to leave as is"
- "not a hill I'll die on"
- "totally fine to leave as is though"

Minors don't need a closer (they're worth doing), but can have "up to you" if genuinely borderline.

---

## Theoretical findings

If the issue only arises in contrived scenarios, lead with "in theory":
> nit: in theory String(rawExternalId) coerces any non-null value, so a numeric external ID would pass through and potentially resolve to an entity. The middleware catches this before we get here though.

If it's truly unlikely, add acknowledgment at the end:
> Unlikely someone would use that though, up to you how to handle it.

---

## Questions

`question:` is for when you genuinely need the author to tell you something you cannot determine from the code — whether something is intentional, whether a ticket covers it, whether a simplification is safe. It is not for observations dressed up as questions.

**Before proposing any `question:`, try to answer it yourself.** Check the PR description, the commit messages, linked tickets, code comments near the finding, and sibling code. If the answer is there, the question is either resolved (drop it) or becomes an observation (relabel as `minor:`/`nit:` citing what you found). Only post a `question:` you actually could not answer.

**Use `minor:` not `question:` when** you've spotted something that looks wrong or missing and you're just hedging the claim. "I think X is untested" is a `minor:`. "Is this intentional?" is a `question:`.

**`question:` comments should be the shortest, not the longest.** Just the question, no setup sentence. The author knows their code.

Bad — too much mechanism before the question, should be shorter or a `minor:`:
> question: with `workflowSlug` not threaded through to `saveWorkflowConfigValues`, I think a request scoped to workflow A can write config for any recipe in the installation's project, while the read path also filters by slug (WorkflowService.ts:137). Is the asymmetry deliberate pending API-378, or should the save scope match?

Good — just the question:
> question: should `saveWorkflowConfigValues` scope by slug the way the read path does, or is that API-378's job?

Another good example:
> question: the new properties have maxLength 255 which matches the varchar columns. The existing ones (e.g. asset.ts) didn't get this, should we align them at some point or not really important?

---

## Precedent links

When pointing at a pattern mismatch, name the file and note where the pattern lives:
> minor: extractEndpoints (spec/restDesignCompliance/endpoint.ts:12) already does this walk...

Don't just say "the codebase does X". Show where.

**File:line references to other files should be GitHub links.** A bare `mapWorkatoMapperToConfigFields.ts:199` forces the reader to go find it; a link doesn't. Build the URL from, in order of preference:
1. A file in the PR diff: `https://github.com/<org>/<repo>/pull/<number>/files#diff-<sha256 of file path>R<line>` 
 or simpler, link to the file at the PR's head commit: `https://github.com/<org>/<repo>/blob/<head-sha>/<path>#L<line>`
2. A file not in the PR: link at the PR's head commit or the repo's default branch HEAD

Use the markdown form `[mapWorkatoMapperToConfigFields.ts:199](url)` so the comment stays readable. The anchor file:line of the comment itself doesn't need a link, only references to *other* locations.

If the codebase is inconsistent, say so:
> "we're inconsistent throughout the codebase on this though..."

And then don't block on it.

---

## What not to say

Never:
- "You should change this to..."
- "This needs to be..."
- "This is wrong because..."
- Long explanations of how the code works (the reader can see it)
- Restating what the severity label already implies ("this is a critical issue" when you labeled it `major:`)
- Passive voice where active is clearer
- "I wanted to flag that..." / "I noticed that..." — just say the thing

---

## The anchor line

The comment goes on the line the reader should look at. Usually that's:
- The function signature if the issue is a missing test for the whole function
- The specific branch or expression that's untested/wrong
- For missing tests: the **production code** line, not the test file

When a finding spans multiple lines, pick the most informative one — usually the line with the decision, not the line with the consequence.

---

## Worked examples

**Finding**: `collectExternalIdsToResolve` has no test exercising the Array.isArray tolerance path inside `visitSchema`.

❌ Draft:
> minor: I noticed that in visitSchema at line 196, there's an Array.isArray guard that checks whether the current body node is an array before iterating. This branch is untested. No test currently exercises the scenario where the schema says array but the body value isn't one. If this guard were removed, no test would fail.

✅ Shaped:
> minor: I think the malformed-body branches are untested, what test fails if the Array.isArray guard breaks?

---

**Finding**: `getExternalIdPaths` returns `readonly ExternalIdPair[]` but is named `getExternalIdPaths`.

❌ Draft:
> nit: There is a naming inconsistency: the function getExternalIdPaths has a return type of ExternalIdPair[], which means the name says "paths" but the type says "pairs". These two concepts should be aligned.

✅ Shaped:
> nit: getExternalIdPaths returns ExternalIdPair[], should the name and type agree?

---

**Finding**: Duplicate literal "Mutually exclusive with **X**" built in two places.

❌ Draft:
> nit: The string "Mutually exclusive with **X**" is constructed identically in two places (lines 93 and 149). A small helper function could serve both call sites and eliminate the duplication.

✅ Shaped:
> nit: is it worth adding a small helper for `Mutually exclusive with **X**`? It's also on line 149. Might not be worth it though
