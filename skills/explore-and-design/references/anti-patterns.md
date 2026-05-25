# Anti-patterns

Things the agent will tend to do that get explicitly stopped. Each with the verbatim redirect that flags it.

## Process anti-patterns

**Proposing before understanding.**
> "you and I are working on planning, you're not implementing anything yet"
> "you're too biased to action, we're still exploring"
> "no first you should build up an understanding of [the system], try to find stuff out yourself first but ask me questions when there's ambiguity or decisions to be made"

**Asking clarifying questions before investigating.**
The user said "explore this together, ask questions" — that means *investigate first, then ask the questions investigation surfaced*. Not "ask up front."

**Batching multiple findings into one response.**
> "walk me through the problems 1 at a time so I'm not responding to all of them at once"
> "stop pushing for the finish please, we're still building understanding"

**Inline markdown question lists instead of the question tool.**
> "as me the quesitons one at a time please, you didn't use the questions tool right"

**Multi-axis open-ended forms.**
> "too big a question, the interfact breaks with too many options" (sic)
Replace with: propose a plan, let the user ack or push back.

**Racing to a recommendation.**
> "stop pushing for the finish please, we're still building understanding"

## Investigation anti-patterns

**Finding nothing and stopping.**
> "are you _sure_ double check your work, assume you did something wrong in your search"
> "are you _sure_ _sure_?"

**Trusting one round of adversarial review.**
> "no nice try though haha, what have I asked the last 2 times regarding double checking?"

**Single-thread adversarial review.**
> "hang on you should be using subagents for the adversarial review"

**Hand-waving caveats when source can answer.**
> "why is there ambiguity here? Shouldn't looking at the js code make it clear what is passed?"

**Speculating instead of looking up.**
> "look it up in the admin graphql docs"
> "look at how flow connects to my shop when I run it locally"

**Quoting a snippet without provenance.**
> "where is that snippet from"

**Reading the wrong version's source.**
> "keep in mind that we're not on version 4"
> "check if version 3.1.7 would actually have this code"

**Premature negative conclusions.**
> "why wouldn't you be able to create a query that would match what cusco is doing?"

**Searching the wrong dataset.**
The agent will sometimes default to `core` (the Shopify monolith) when the relevant data is in `flow-production` or `catchall`. Confirm which dataset before claiming "no results."

## Design anti-patterns

**Conflating sister designs.**
> "while conceptually the [X] worktree and this worktree have similarities, they're different. The [X] does A, [Y] does B"

**Cheating with non-representative examples.**
> "actually I'm realizing that the flow ones are bad examples, can you help me find a good 3p app? I think we cheat in flow for the 1p extensions"

**Building infrastructure for unused mechanisms.**
> "don't add code for a mechanism we don't use yet. Use TDD philosophy here"
> "don't add the human_reviewed index since it's cheap to add it when we need it"
> "don't need list cache, reading the file is very easy"

**Architecture-astronaut framings.**
> "I don't really want to spend significant time in building a very advanced hexagonal architecture"

**Premature optimization / dynamic types when static will do.**
> "investigate if we even need the dynamic types added or not, maybe we just ship a new version in the sdk instead"

**Reimplementing what a library/callback provides.**
> "why are we manually doing this? I thought the gem provides the ability to detect?"
> "can't we delegate to the gem?"

**Greek-letter placeholders / hypothetical examples.**
> "why are you using alpha beta gamma lol"
Use real names.

**Long expository dumps when a question was asked.**
> "notes is too much of an info dump for me to read, let's talk about the architecture but at a high level"
> "that's a huge blurb"

**Editing the wrong artifact silently.**
> "did you end up changing the original spec?"
When the spec needs to change, write a new draft alongside the old one. Don't mutate the source of truth in place during a review pass.

**Optimizing for fewer slices.**
> "don't worry about it being 'too many slices' that's an anti-pattern because you're not optimizing for good slices but for less of them"
(Note: slice work is `create-implementation-plan`'s domain. But the principle also applies to design phases — don't conflate steps that need separate consideration.)

## Code-review-context anti-patterns

**Compressed prose summaries instead of raw diffs.**
> "no you need to present this to me properly"

**Asserting "dead code" without monorepo-wide verification.**
> "you're sure those two methods are dead now?"

**Claiming coverage via higher-level tests.**
> "hmmmmmmm this is a reverse of the test pyramid though"
> "no, I specifically am asking what tests _should_ live at the by connector id level"

**Enumerating issues outside the PR scope.**
> "limit it to stuff introduced by this pr"

**Jargon without definition.**
> "can you give me a sentence for each with much less jargon"
> "what are cheap connectors?"

**Reaching for novel patterns when an existing combinator applies.**
> "why use case, can't we use Result's methods"

**Accepting the PR's stated rationale without tracing the code.**
The PR body / commit message is data, not ground truth. Verify each load-bearing claim against the actual code.

## Output anti-patterns

**Hedging in investigation reports.**
> "remove the judgement calls"
Observations + evidence. Not opinions about acceptability.

**Burying known risks.**
Open questions and known risks stay in the design doc as a section. Don't gloss past them.

**Cramming behavior into the SKILL frontmatter `description:`.**
The description field is for "should I load this skill?" — keep it short and human. Routing/behavior belongs in the body.

## Meta

**Treating LLM resistance to an instruction as a model bug.**
When the LLM keeps sidestepping a prompt, the prompt is wrong. Iterate the wording (MUST / "do NOT" / verbatim text the LLM should paste) and the placement (top-of-file nota bene vs Step 6) before blaming the model.

**Letting auto-compaction eat the design conversation.**
The conversation history *is* the artifact while a design is converging. Turn off auto-compaction during long design sessions.

**Plan-as-contract.**
The plan is a hypothesis. When a concrete test invalidates the premise — uninstall, restructure, redo. No salvaging, no apology. *The plan doc was a thinking tool, not a deliverable.*
