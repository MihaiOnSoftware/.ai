---
name: coordinating-children
description: Coordinates async children and nested supervisor requests in pi conductors. Use when a conductor launches specialists, waits headlessly, or relays a child's decision request to its own supervisor. Not for leaf specialists.
---

# Coordinate owned children

Before dispatch, require `subagent`, `bg_wait`, `contact_supervisor`, and `subagent_supervisor` in the resolved conductor tools, with blocking waits enabled. Missing tools or disabled blocking waits are a blocked prerequisite before launch, not a reason to substitute intercom or do specialist work inline. Keep inherited delegation and depth limits.

## Dispatch and wait

1. Launch the specialist asynchronously. Include this stop condition in its task: "If contact_supervisor is unavailable or a decision request times out, return BLOCKED with the question and run state instead of asking again."
2. In a nested/headless conductor, await owned async children with blocking `bg_wait({ id: "<run id>" })`. An interactive top-level session may yield for native completion instead. A launch receipt is not a completed result.
3. If waiting is disabled or unavailable after launch, pause active owned descendants leaf-first, confirm paused/terminal states, and return `BLOCKED` with run ids instead of waiting again. When the wait returns attention, inspect `subagent_supervisor({ action: "pending" })` and the child's status. Answer requests as below, then wait again. A wait window elapsing leaves the child running; inspect its state before waiting again, rather than treating the timeout as completion.
4. Consume the completed result and any report it names before advancing. Do not return the final slice or phase report while an owned child is still running.

## Answer the requesting child

For A -> B -> C, C's request belongs to B. B inspects and answers it with `subagent_supervisor`, not intercom or steering.

1. Retain C's original request id. If the answer is within the approved task, reply with `subagent_supervisor({ action: "reply", replyTo: "<C request id>", message: "<answer>" })`.
2. If A's decision is needed, B asks A separately with `contact_supervisor` (`need_decision` or `interview_request`). A's reply resolves only B's request. B must then reply to C using C's original `replyTo` id.
3. If upward contact is unavailable or times out, stop that escalation after one attempt. Where possible, reply to C's original request with the blocker and an instruction to stop safely and return partial state, not permission to proceed. Otherwise interrupt the owned child with `subagent({ action: "interrupt", id: "<run id>" })`. Confirm it is paused or terminal before returning `BLOCKED` with run ids, the unresolved question, and partial work. Do not repeat unanswered requests or claim the phase completed.

Nested conductors route approvals and blocked results to their spawning supervisor. Interactive top-level conductors ask the user. Keep explicit approval checkpoints; relaying a request does not grant approval.
