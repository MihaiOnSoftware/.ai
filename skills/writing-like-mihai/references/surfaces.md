# Surfaces

Defaults for each surface the skill covers. Everything here yields to the input and to the request. A template the user supplies replaces the default structure, and the input's facts, uncertainty, owners, dates, health, commitments, person and the author's own questions outrank everything here. A limit in the request replaces the length budget and is a hard limit: count the words and cut until under it. The budgets below apply only when the request sets none, and any instruction in the request ("make it longer", "ask both questions", "leave out the review mechanics", "do not propose a fix", a section order) overrides the matching default structure, cap or drop list. Question caps limit what you add. They never remove a question the author wrote.

## TSD or design note

- Reader: engineers who will build or review it and did not do the investigation.
- Default structure: problem, decision, alternatives considered (one or two lines each, with the reason), scope or non-goals, risks, open questions. A supplied template replaces this, with no title above its first heading.
- Decisions: state a decision as decided when the input says so. A proposal or a lean stays labeled as one.
- Risks: carry the likelihood the input gives and no more.
- Length: as long as the decisions need, and no narrative.
- Question cap: none outside the open questions section. List only what is open, one numbered item each.
- Never add: a decision, a rejected alternative, a risk or a task the input does not contain.
- Drop: how long the investigation took, dead ends, tool names, notes to self, abbreviations coined along the way.

## Issue description

- Reader: whoever picks it up, possibly weeks later, with none of today's context.
- Default structure: context (the symptom or need in one to three sentences), what to do, out of scope, links.
- What to do: when the cause is only suspected, say confirm first and then fix. Give acceptance criteria only when the input states them.
- Length: under about 150 words.
- Question cap: 1.
- Never add: priority, owner, estimate, a new task, or a fix approach the input does not give.
- Drop: the story of how the problem was found, and anything the linked ticket or thread already says.

## Project or status update

- Reader: leadership or stakeholders outside the daily work.
- Default structure: the supplied template, exactly: its headings, its order, nothing above the first heading. This skill embeds no team template. If none is supplied, ask for it, or lead with outcomes and changes since the last update.
- Numbers: keep percentages exactly as given and say what they measure.
- Length: under about 150 words.
- Question cap: 0, unless the template asks for one.
- Never add: health, risk or a slip inferred from undated milestones or from remaining work, or a blocker widened from the one item it affects to the whole project. An update that states its own health keeps it, and health goes in the body only when the destination has no separate health field.
- Drop: PR numbers and hashes, review mechanics, branch and merge arrangements, who is reviewing what, agent activity, and detail the audience can open elsewhere.

## Slack message

- Reader: teammates who share the context.
- Default structure: the point in the first sentence, the context second, at most one ask, all in one message. Detail belongs in a thread.
- Register: casual is permitted and never added. Keep the casual markers the input has. Do not introduce slang or profanity.
- Length: under about 90 words.
- Question cap: 1.
- Never add: urgency, a deadline or a tag the input does not give.
- Drop: greetings that delay the point, headings and bold lead-ins, more than two bullets.

## Email

- Reader: often someone with less context, sometimes outside the company.
- Default structure: a proposed subject line, a first sentence that says what and by when, one ask, what stays unchanged when that matters, a plain sign-off with no name unless the input or request gives one, complete sentences.
- Length: under about 180 words.
- Question cap: 1.
- Never add: a sender name, title, role, deadline or commitment the input does not give.
- Drop: pleasantries before the point and a message-by-message replay of the thread.

## Other report-like prose

Incident summaries, investigation summaries, weekly notes and similar write-ups for people who did not do the work.

- Default structure: the outcome, then the evidence, then next steps labeled as suggested or agreed exactly as the input labels them. Use headings only when supplied, and add no title above them.
- Length: under about 200 words unless asked for more.
- Question cap: 0.
- Never add: a conclusion, a cause, a speculation, a judgment call or agreement the input does not state.
- Drop: the order things were tried in, agent identifiers and run IDs, process notes and abandoned attempts.
