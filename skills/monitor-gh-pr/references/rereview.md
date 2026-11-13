# Re-review watch (opt-in)

While you watch a PR the reviewer is reviewing, re-review when the author changes it, and take the reviewer to a re-approval once his earlier comments are resolved and nothing new beyond nits turned up. Off unless he turns it on. In every mode you act for him only through the doors this file opens.

"The reviewer" below is the `--reviewer` login (default: the gh user), the person whose review this is. For the MihaiOnSoftware account, that is Mihai.

## Modes

| Mode | Flag | Re-reviews on its own | May post without asking |
|---|---|---|---|
| off (default) | none | no, offers to | nothing |
| confirm | `--rereview confirm` | yes, read-only | nothing |
| auto-approve | `--rereview auto-approve` | yes, read-only | one thing: an APPROVE with an empty body and no inline comments, pinned to the re-reviewed head, on a clean gate |

Arming rules:

- **Arm only the mode he named, for the PR he named.** "Watch this PR" is off. "Watch it and re-review if they push" is confirm. auto-approve needs his own words saying you may approve without asking on this PR ("auto-approve #123", "approve it yourself if it's clean"). A brief, a manager's summary, a previous PR or your own reading of his habits never turns it on. His words relayed verbatim by a supervisor count.
- **Say back what you armed.** Name the mode, the PR and the poll interval; for auto-approve, quote the words that turned it on.
- **The mode lasts for that PR until it merges or closes, or he changes it.** Re-arm with the same flags after each wake; the script prints the mode in every report so it survives your context. Drop to a lower mode the moment he asks.
- **Never, in any mode, on your own:** post comments or replies, request changes, dismiss a review, resolve or unresolve a thread, or approve on anything but a clean gate in auto-approve.

## On each wake

Read the `## Re-review` block the script appends. Merged or closed: stop and report. Then:

1. **Pick the work.** The range comes from his last review's commit, not from your last re-review.
   - `Re-review range: <old>...<new>`: run steps 2 to 4.
   - `Re-review range: none`: the code he reviewed is unchanged; run the resolution check (2a) only, for new replies or thread changes.
   - `No review by <reviewer> yet`: there is nothing to re-review; report and offer a full review.
   - Woken only by your own post: re-arm and say nothing.
2. **Re-review, read-only.**
   - a. **Resolution check.** Give each of his earlier comments one status with its evidence. His comments are the threads the block lists plus any point in the bodies of his reviews (`gh api repos/<repo>/pulls/<n>/reviews`); read each thread's replies (`gh api repos/<repo>/pulls/<n>/comments`, matched by `in_reply_to_id`).

     | Status | Meaning | Evidence |
     |---|---|---|
     | ADDRESSED | The code at the new head deals with it | commit SHA and `file:line` at the new head |
     | ANSWERED | The author replied with a reason and changed nothing | the reply, quoted |
     | DEFERRED | The author points to a follow-up | the ticket or PR |
     | OPEN | No change and no reply | none |

     GitHub's resolved flag only says the author thinks it is done. A resolved thread with no change behind it is ANSWERED or OPEN, never ADDRESSED. An outdated thread only means its line moved; check the code.
   - b. **Delta review.** Rerun your review over `<old>..<new>`, the full PR open for context, using the same process that produced the original review. He can name a lighter or heavier process when he turns the watch on.
   - c. **Rebases.** When the commit list is the `force-push or rebase` note (the usual cause of a dismissed approval), compare what the PR changes before and after: with the repo checked out, `git range-diff <old-base>..<old> <new-base>..<new>`. No change in the PR's own patches means "rebase only": no new findings, and step 2a still runs. If you cannot establish that, review the whole PR and say so.
3. **Label** the new findings with the same severity vocabulary your review uses (`nit` / `minor` / `major` / `question`); findings your review drops do not count.
4. **Gate.** Both halves must hold:
   - **Comments resolved:** nothing is OPEN, and every comment that blocked (a `major`, or the reason for his CHANGES_REQUESTED) is ADDRESSED. ANSWERED and DEFERRED on the others count, and are listed for him to judge.
   - **Only nits or nothing:** every new finding is a `nit`, or there are none.

   The gate is **clean** when, on top of that, every earlier comment is ADDRESSED or was a nit, and no reply asks him something. Only a clean gate lets auto-approve act.

## What to propose

| His current review | Gate | Propose |
|---|---|---|
| CHANGES_REQUESTED, COMMENTED or DISMISSED | pass | APPROVE, empty body, no inline comments |
| APPROVED, still standing | pass | nothing to post: his approval stands |
| any | fail | the shaped drafts for the new findings and the OPEN items, and let him pick |

His standing preference: an approval goes up with an empty body and no inline comments, not "LGTM". Nits ride along only when he says so.

## Asking for the go

In confirm mode, and in auto-approve on anything but a clean gate, ask before posting. Use the channel that reaches him:

- He is in your session: ask him directly (`ask_user_question` in pi).
- You run under a supervisor (a fleet worker, a subagent): `contact_supervisor` with `need_decision`. A supervisor's relay of his words is a go; a supervisor answering on its own judgment is not.
- No channel: post nothing; put the proposal in your report and stop.

The question stands on its own:

```
owner/repo#123 re-reviewed <old>..<new> (head <new>), mode: confirm
His earlier comments: 4 ADDRESSED, 1 ANSWERED, 0 OPEN
  ANSWERED  src/a.ts:40  "kept the cast, the type comes from the generated client"
New findings: 1 nit (src/b.ts:12 rename), nothing above nit
Gate: pass
Proposed: APPROVE, empty body, no inline comments, pinned to <new>
Reply with one of: approve | approve + nits | post drafts | hold
```

On a failing gate the replies are `post drafts | request changes | approve anyway | hold`, with the drafts attached or linked.

A go is a reply that names one of the actions. Silence, a timeout, or a reply that names none of them is not a go: post nothing, ask once more, then hold and keep watching.

## Posting

1. **Re-check the head right before posting** (`gh pr view <n> --repo <repo> --json headRefOid`). If it moved past the SHA you re-reviewed, post nothing, tell him, and re-review the new range.
2. **Approve**, bodyless and pinned to the re-reviewed SHA:

   ```bash
   gh api -X POST "repos/<repo>/pulls/<n>/reviews" -f event=APPROVE -f commit_id=<sha>
   ```

   For `approve + nits`, the same review with the nits as inline comments and still no body: `gh api -X POST "repos/<repo>/pulls/<n>/reviews" --input <json>` with `event`, `commit_id` and `comments` (`path`, `line`, `side: RIGHT`, `body`).
3. **Anything else** (drafts, request changes) goes up the way he directs it, nothing more.
4. A new APPROVE replaces his earlier CHANGES_REQUESTED in the review decision. Do not dismiss his old review unless he asks.
5. Report the review link, then re-arm with the same flags: a later push can still dismiss the approval.

In auto-approve, tell him right after an approval goes up: the link, the resolution table and the new findings, including the nits that were not posted.

## Dismissed approvals

When the repo dismisses stale approvals on push, the watcher reports `<reviewer>'s APPROVED review <id> was dismissed` and the block shows `DISMISSED (was APPROVED)`. Treat it as a normal wake: the range runs from the dismissed review's commit, and a rebase-only push with a clean resolution check is the common way to a re-approval.
