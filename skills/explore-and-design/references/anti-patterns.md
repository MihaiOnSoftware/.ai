# Anti-patterns

Redirects the user reaches for during design work, verbatim, each with a pointer to the rule or step it enforces. When you notice one of these coming, you've drifted from that rule.

## Process

**Racing to a recommendation.** → Steps 1 to 3 before Step 4
> "you're too biased to action, we're still exploring"
> "stop pushing for the finish please, we're still building understanding"

**Asking before investigating.** → Rule 1
> "can you answer this question yourself?"
> "no first you should build up an understanding of [the system], try to find stuff out yourself first but ask me questions when there's ambiguity or decisions to be made"

**Batching findings, or dumping notes.** → Step 4.1
> "walk me through the problems 1 at a time so I'm not responding to all of them at once"
> "notes is too much of an info dump for me to read, let's talk about the architecture but at a high level"

**Inline question lists or oversized forms.** → Step 4.2
> "as me the quesitons one at a time please, you didn't use the questions tool right"
> "too big a question, the interfact breaks with too many options"

**Designing against stale requirements.** → Step 1.1 and 1.2
> "re-check the 374 requirements they may have changed"
> "check my recent messages with Maxime in Slack, also his concern on the original PR around special handling. Does this plan address those?"
> "so I guess don't proceed to implementation since you designed the wrong thing"

**Posting on the user's behalf.** → Rule 4
> "I will handle all comms please do not post anything on slack... ever"
> "look at the inline comments from Maxime, investigate/fix if simple but DO NOT comment on github"

**Editing the source of truth during review.** → Step 1.3
> "did you end up changing the original spec?"

## Investigation

**Finding nothing and stopping.** → Step 3.3, and the are-you-sure ladder in investigation-tactics.md
> "are you _sure_ double check your work, assume you did something wrong in your search"
> "no nice try though haha, what have I asked the last 2 times regarding double checking?"

**Reviewing in your own context.** → Step 3.3. Launch every reviewer as a fresh subagent, never forked from your session.
> "hang on you should be using subagents for the adversarial review"
> "hang on a sec, have you been forking your subagents? Never fork please"

**Hand-waving when source can answer.** → Step 4.4
> "why is there ambiguity here? Shouldn't looking at the js code make it clear what is passed?"

**Quoting without provenance, or paraphrasing code.** → Rule 2
> "where is that snippet from"
> "don't fucking paraphrase the code"

**Reading the wrong version.** → evidence ladder rung 3
> "keep in mind that we're not on version 4"

**Probes that prove nothing.** → Step 3.2
> "this poc that you're proposing doesn't really prove much, all it does is show that the pieces are in fact there... which we kind of know they are"

**Accepting stated rationale.** → evidence ladder rung 5. A PR body, ticket, or TSD is a claim to verify against the code.

## Design

**Ignoring precedent.** → Step 2.2
> "does this match the pattern elsewhere"
> "what's the more common pattern in REST for this tyep fo thing?"

**Conflating sister designs.** → Rule 3
> "while conceptually the [X] worktree and this worktree have similarities, they're different. The [X] does A, [Y] does B"

**Building for unused mechanisms, or over-architecting.** → Rule 5
> "don't add code for a mechanism we don't use yet. Use TDD philosophy here"
> "don't add the human_reviewed index since it's cheap to add it when we need it"
> "I don't really want to spend significant time in building a very advanced hexagonal architecture"

**Pre-picking among alternatives.** → Step 4.3
> "don't assume we're going just with the second proposal, we might still go with the configuration parameters, I want to have things to compare"

**Placeholder names.** → design-doc-shape Style
> "why are you using alpha beta gamma lol"

## Output

**Jargon and process details in outbound text.** → Step 5 and the distillation example
> "The above is way to jargon heavy and uses too much abbreviation which makes it unreadable. Don't include tangential information unless valuable. Do not include process details"
> "double check for internal language that's only relevant because of your specific context"

**Judgement calls in reports.** → design-doc-shape Style
> "remove the judgement calls"
