# Examples

All of these are invented. They show shape, not wording to copy. Each pair ends with the rule it illustrates.

## Contents

1. TSD: a proposal stays a proposal
2. Issue description: suspected cause means confirm first
3. Project update: undated means no risk language
4. Slack: almost good, returned unchanged
5. Email: the point first, one ask
6. Report-like prose: condensation
7. Email rewrite: one fix, one-line note, no invented sender

## 1. TSD: a proposal stays a proposal (draft from notes)

Before:
> Looked at the retry options for the billing worker. Spent two days on it. Tried a cron sweep first, dead end. Leaning toward a queue with backoff, haven't confirmed the queue can hold the volume. Not doing anything about dedupe here.

After:
```text
Problem: Choosing how the billing worker retries.
Proposal: Retry through a queue with backoff. This is a lean, not a decision.
Alternatives considered: A cron sweep. Tried first and it was a dead end.
Non-goals: Deduplication.
Risks: The queue may not hold the volume. Not yet confirmed.
Open questions:
1. Can the queue hold the volume?
```
What changed and why: "Leaning toward" stays a lean and the unconfirmed volume stays unconfirmed. The two days are dropped, and no reason is given for the dead end because the notes give none. (TSD rule: never add a decision or risk.)

## 2. Issue description: suspected cause means confirm first

Before:
> So this came up in standup and Dana noticed exports are sometimes empty, I think after the timezone change but not sure. We should probably fix the date filter, high priority.

After:
```text
Context: Some exports come back empty. This may have started after the timezone change. That is not confirmed.

What to do: Confirm whether the timezone change causes it. The date filter is the probable fix.

Priority: High.
```
What changed and why: The cause is only suspected, so the steps are "confirm first, then fix", and the date filter stays "probable", as in "should probably". "High priority" is kept because the input states it, and nothing is added about owner or estimate. The standup story and Dana's name go. (Issue rule: confirm before fixing; never add priority, owner or estimate.)

## 3. Project update: undated means no risk language

Supplied template: Done / Next / Needs.

Before:
> Done: finished the importer migration. Next: the reporting cutover, no date yet, and there is still a lot of work left. Needs: nothing.

After:
```text
Done
Finished the importer migration.
Next
The reporting cutover. No date yet.
Needs
Nothing.
```
What changed and why: The headings and order are binding. "A lot of work left" with no date is not evidence of a slip, so it is cut and no risk or health is added. (Update rule: never infer risk from undated milestones.)

## 4. Slack: almost good, returned unchanged

Before:
> hey folks, the nightly sync is back after the config fix. Watch tomorrow's run and shout if the counts look off.

After:
```text
hey folks, the nightly sync is back after the config fix. Watch tomorrow's run and shout if the counts look off.
```
Note: Fine as is. The point is in the first sentence, there is one ask, and the casual register is the author's own. Optional word-level tweak: "is back" to "is running again".

What changed and why: Nothing breaks a rule, so the text comes back unchanged with a one-line verdict and one optional swap that adds no information. A longer, tidier rewrite would be an over-edit. (Rewrite mode: edit the minimum.)

## 5. Email: the point first, one ask

Before:
> Hi Sam, hope this finds you well! I wanted to reach out about a small thing. Our sandbox key expires on the 14th and I was wondering if you might be able to send a new one? We'd keep using the same endpoints.

After:
```text
Subject: Sandbox key expires on the 14th

Hi Sam,

Our sandbox key expires on the 14th. Could you send a new one? We'd keep using the same endpoints.

Thanks,
```
What changed and why: The pleasantry and "I wanted to reach out" are cut so the first sentence carries the fact. The subject uses only the expiry date the input gives. The input sets no deadline for the new key, so none is added, and "We'd keep using" stays as hedged as written. (Email rule: never add a deadline or commitment.)

## 6. Report-like prose: condensation

Before:
> 01:50 got paged, export job failing. Looked at the dashboard first, nothing obvious, the queue looked normal. Restarted the job at 02:10 and it failed again. Ravi checked the worker logs, lots of write errors and nothing else in there. Spent a while on the queue settings, no change. Meera then found the disk was full. Ravi cleared old files from the export folder and reran the job, and it passed at 03:05. The retention setting might be too long, nobody has looked at it yet. Meera thinks we should probably add a disk alert, no ticket for it yet. The dashboard was also slow all night, probably unrelated, didn't dig into it. Wrote the log paths into the team notes in case it comes back. Went back to bed around 03:30 after checking the next scheduled run was queued. Took longer than it should have because the first page went to the wrong channel and nobody saw it for a while.

After:
```text
The export job passed on a rerun at 03:05, after Ravi cleared old files. Meera had found the disk was full.

The retention setting might be too long. Nobody has looked at it yet. Meera thinks a disk alert should probably be added.
```
What changed and why: Outcome first, then who found and did what, then next steps, with no headings because none were supplied. The restart, dashboard, queue settings, log paths and the slow dashboard are dropped. "Might" and "probably" stay, and the alert stays Meera's view, not an agreed step. (Report rule: never add a conclusion, cause or agreement.)

## 7. Email rewrite: one fix, one-line note, no invented sender

Before:
> Subject: Staging refresh moved to Friday
>
> Hi Priya,
>
> Just a quick note before the weekend. The staging refresh moves from Wednesday to Friday this week because the import is still running. Nothing changes for production. Let me know if Friday is a problem.
>
> Thanks,

After:
```text
Subject: Staging refresh moved to Friday

Hi Priya,

The staging refresh moves from Wednesday to Friday this week because the import is still running. Nothing changes for production. Let me know if Friday is a problem.

Thanks,
```
Note: Fine apart from the opener, which delayed the point and is cut. Nothing else changed.

What changed and why: One sentence breaks a rule, so one sentence goes and the rest comes back word for word. The note tells the writer what moved so they do not have to compare drafts. The input names no sender, so the sign-off stays unsigned rather than gaining a name. (Rewrite mode: edit the minimum and say what changed; email rule: never add a sender name.)
