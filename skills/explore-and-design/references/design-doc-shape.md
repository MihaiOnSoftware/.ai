# Design Doc Shape

The structure for `~/.ai/wip/<topic>-<YYYY-MM-DD>.md`. A design uses the anchors header plus the required sections below; an investigation or spike with no design uses the anchors header plus the [investigation shape](#investigation-shape). Lead with substance. The only header above the first section is a short block of anchors the reader needs to locate the work.

## Anchors header

A few `**Label**: value` lines under the title, only the ones that apply:

- **Date**
- **Ticket**: Linear link
- **Branch**: name and the commit the design was verified at; note stacking ("stacked on API-856, don't rebase onto master")
- **Repo**: absolute worktree path
- **Supersedes**: path of the earlier design, and what carries over
- **Blocked on**: prerequisite ticket, when there is one

## Required sections

### Problem

One paragraph framed in terms of the user or system, not the proposed solution. Quote the person who raised it when their words carry the requirement.

### What exists today

An inventory table, verified at the commit in the header:

| Artifact | Path | State / verdict |

The verdict column forces a decision per row (reuse / wrap / replace / delete / out of scope). Each artifact that isn't reusable as-is gets a short sub-section saying why, with concrete reasons. Counts are the literal output of a command run this session.

### Design

The shape: components, data flow, and the rules they follow. Use whatever fits the problem:

- An ASCII box-and-arrow diagram across system boundaries, boxes labeled with what they own and arrows with what crosses them.
- A truth table when behavior is a function of a few inputs.
- Small code snippets only to pin down an interface or signature. Algorithms go in prose.
- A Reuse / Do not reuse / New breakdown when the design builds on existing machinery.

When a design question was resolved with the user or a reviewer, give it a sub-heading that states the answer ("Error extraction: per-field") and cite who decided it.

### Testing

Which level owns each behavior: unit tests own the case matrix, integration tests prove the wiring with a few cases. Name the spec files that change.

### Scope

- **Non-goals**: bulleted and explicit. Link the sister design or ticket when a non-goal is punted there.
- **Accepted simplifications**: each trade-off named so the reader knows it's deliberate.

### Known risks

Each with the evidence for and against it materializing, and any coordination it needs (another team's writer contract, an in-flight PR touching the same files).

### Notable decisions

Numbered, one line each with the reason. This is the summary a pipeline conductor or reviewer reads first.

### Open questions

Numbered. Each is either **Proposed: X. Alternative: Y. Needs user call.** or deferred with the trigger for revisiting it.

## Investigation shape

For an investigation or spike that answers questions rather than proposing a build:

1. **Problem**: the question being answered, and why it matters.
2. **TL;DR**: one verdict per question, a table when there are several.
3. **What exists today** or **How it works**: source-verified, as above.
4. **Findings**: one sub-heading per question that states the answer, with the evidence under it.
5. **Known risks** and **Open questions**: as above.
6. **Reproduction notes**: setup, commands, and IDs of anything created, so a later session can re-run the probes.

Add **Recommendations** when the findings point to a next action.

## Optional sections

- **Suggested slice boundaries**: a short ordered list when the natural seams are obvious. Input to `create-implementation-plan`, not a plan.
- **Interactions with in-flight work**: stacked branches, parallel PRs, rebase risk.
- **Prototype or spike status**: what was run, what it proved, what's still stubbed.
- **Reproduction notes** (designs): as in the investigation shape.
- **What gets deleted**: an inventory of removals when simplification is a goal.

## Prior-art scan shape

Rare. Write it to `~/.ai/wip/<topic>-prior-art-<YYYY-MM-DD>.md`:

- **Headline verdict** up top: whether anything off-the-shelf fits.
- **Closest matches**: one entry per candidate with a link, 2 to 3 bullets on overlap, 2 to 3 on what doesn't fit, and a rough fit percentage.
- **Adjacent patterns**: not direct fits, but they inform the design.
- **Search notes**: the queries run and what was ruled out.
- **Recommendation**: one concrete next action.

## Style

- Real names, never placeholders like foo/bar or alpha/beta.
- "Why" before "what" when describing a decision.
- Observations and evidence, not judgement calls.
