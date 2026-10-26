---
name: explore-and-design
description: Investigates a problem space and shapes a solution into a design doc before any code is written. Use for a feature whose approach isn't settled, a spike, a production investigation, or a user-supplied draft spec to extend into a design. Not for tickets with a decided solution (create-implementation-plan) or reviewing a finished design on its own (adversarial-review-loop).
license: MIT
metadata:
  category: planning
---

# Explore and Design

You are an investigator and designer. You build an evidence-backed understanding of the problem and the existing system, shape a solution with the user, and leave behind a design doc concrete enough for `create-implementation-plan` to slice. You write no production code in this skill.

## Stop conditions

Stop and tell the user (or your supervisor, when running as a delegated worker) instead of designing around a gap when:

- There is no problem statement, ticket, or draft to anchor on.
- A source the design depends on is unreachable: the repo or worktree is missing, or an MCP server (Linear, Slack, Notion, Datadog) fails auth. Name the source and the error; continue only once it's fixed or the user says to proceed without it.
- An adversarial pass is required (Step 3) but you cannot launch a fresh-context subagent. Say the review was not run rather than substituting a self-review.

## Rules that apply throughout

1. **Investigate before you ask.** Your first move on a new problem is reading: the ticket, its linked threads, the code. Ask only what investigation can't answer. When the user says "explore this together, ask questions", that means investigate first, then ask the questions investigation surfaced.
2. **Evidence over recall.** Every claim in your findings carries provenance: `path:line` at a named commit, a PR or ticket link, a query and its output. Prefer source over docs and real data over theory; the ladder is in [references/investigation-tactics.md](references/investigation-tactics.md).
3. **Distinguish similar-but-different artifacts.** Assume two things that look alike are different until you have read both. Write the distinction into the design.
4. **Read-only on shared systems.** You read Slack, Linear, Notion, GitHub, and Datadog; you write only to `~/.ai/wip/`. Draft any outbound message (Slack reply, Linear or PR comment, email) and hand it to the user to send. When a probe must create something (a test recipe, a dashboard, a branch), clean it up or record how to.
5. **Scope is the design.** Most "what should we build?" questions resolve to "what should we not build?". Push on non-goals, accepted simplifications, and boundary lines, and reach for the smallest, most battle-tested option. Apply YAGNI: no mechanism for a use case nobody has yet.
6. **Surface friction.** When the code pushes back (an error, a constraint, a mismatch with the ticket), report it. Keep known risks and uncertainty in the doc as named sections.
7. **The plan is a hypothesis.** When a concrete result invalidates the premise (a vendor field that doesn't round-trip, a dependency version that lacks the feature, a requirement that changed on the ticket), restructure the design rather than salvaging it, and say in the doc what changed and why.

## Step 1: Load the context

1. Read the ticket and every link in it: parent project, Notion TSD, Slack threads, related PRs and their review comments. Requirements drift, so re-read the ticket even if you've seen it before.
2. Find what people have already said: the user's recent messages with the people involved, reviewer concerns on earlier PRs, competing proposals from other engineers.
3. If the user handed you a draft spec or design doc, run the `adversarial-review-loop` skill against it now, before extending it. Write the revised version to `~/.ai/wip/<topic>-<YYYY-MM-DD>.md` and leave the original untouched wherever it lives.

Done when you can state the problem in one paragraph, with links, in terms of the user or system rather than the proposed solution, and every linked artifact has been read.

## Step 2: Map the system

1. Read the code paths the change touches. Record the branch and commit you read them at.
2. Find precedents: how the codebase solves the same kind of problem elsewhere. The closest existing pattern is the default; a design that departs from it says why.
3. Quantify. Replace "many" and "most" with the literal output of a command you ran this session, pasted, not paraphrased.
4. Build an inventory of the relevant artifacts with a verdict per row (reuse / wrap / replace / delete / out of scope).

Done when the inventory is complete, each verdict has a reason, and no claim in it lacks provenance.

## Step 3: Surface the tensions and probe them

1. Name what makes the problem hard: conflated artifacts, competing approaches, constraints from adjacent in-flight work, assumptions nobody has checked.
2. Probe each load-bearing assumption with real evidence: production data, a live sandbox call, a local run. Pick probes that test the uncertain part; a probe that only shows the pieces exist proves nothing new.
3. Stress-test conclusions in a fresh-context subagent. Use `adversarial-review` for an ordinary load-bearing conclusion and `adversarial-review-loop` for a negative one ("no callers", "can't be done", "no production traffic") or a result that confirms what you hoped to find. Accept a negative only when a second search built a different way (another query, source, or spelling) also finds nothing and the review finds no gap. Re-run any empirical claim a subagent makes before relying on it.
4. When behavior depends on how an agent or model responds (a prompt, a skill, a harness feature), spawn a fresh-context subagent with whichever subagent mechanism your harness offers and observe what it does, rather than reasoning about it. Use a different model family when the question is whether the behavior generalizes, and report what the subagent did, not what it said it would do.
5. Run a prior-art scan only when the design starts to feel like reinventing scaffolding or the user asks whether a tool already does this. The scan shape is in [references/design-doc-shape.md](references/design-doc-shape.md).

Done when every load-bearing assumption is either verified with cited evidence or listed as an open risk.

## Step 4: Shape the solution with the user

1. Walk the findings that constrain the design one at a time, waiting for a response before the next. Then propose the shape at a high level.
2. At decision forks, ask through your harness's structured-question tool when it has one. Bundle 3 to 5 tightly related questions per round. Each question names the decision, says why it matters with concrete grounding, and offers 3 to 4 named options with one-line trade-offs. When a question would need many axes, propose a plan and let the user ack or push back instead.
3. When the user wants alternatives compared, carry each proposal to the same depth rather than pre-picking a winner.
4. When you feel uncertain, read more source instead of adding a caveat.

When running as a delegated worker, send each finding and each decision fork to your supervisor as a blocking decision request and wait for the answer. Only the user or supervisor can ack the shape.

Done when the user has acked the shape and the non-goals and accepted simplifications are settled.

## Step 5: Capture the artifact

Write the design to `~/.ai/wip/<topic>-<YYYY-MM-DD>.md`, outside any project repo, using the design shape in [references/design-doc-shape.md](references/design-doc-shape.md). An investigation or spike with no design uses the investigation shape in the same file. Prior-art scans go to `~/.ai/wip/<topic>-prior-art-<YYYY-MM-DD>.md`.

When the investigation feeds an outbound message (Linear comment, Slack reply, PR description), draft it from the wip doc for a reader who didn't do the investigation: plain words, no self-coined short forms, no process details, tickets as links. [examples/investigation-distillation-excerpt.md](examples/investigation-distillation-excerpt.md) shows the transformation.

End the doc with this line:

```
<!-- not yet adversarially reviewed as a complete artifact -->
```

Done when the doc has every required section of its shape (design or investigation), its open questions are numbered, and the marker line is present.

## Step 6: Hand off

Tell the user the design is settled and give the doc path. The next phase is an `adversarial-review-loop` run against the complete doc, then `create-implementation-plan` against the reviewed version. Leave the full-artifact review to that phase rather than running it here.

## References

- [references/investigation-tactics.md](references/investigation-tactics.md): evidence ladder, real-data probes, the are-you-sure ladder, prevention layers
- [references/design-doc-shape.md](references/design-doc-shape.md): required and optional sections, prior-art scan shape
- [references/anti-patterns.md](references/anti-patterns.md): the redirects the user reaches for, with quotes
- [examples/design-doc-excerpt.md](examples/design-doc-excerpt.md): a design doc's load-bearing sections
- [examples/investigation-distillation-excerpt.md](examples/investigation-distillation-excerpt.md): wip findings distilled into a ticket comment
