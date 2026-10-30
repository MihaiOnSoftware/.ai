Vendor Sync status dump, compiled 2026-10-29 from Linear, GitHub and Slack

Project P-PLT-2210, target December 4. 14 issues total, 6 done, 3 in progress, 5 backlog.

Milestone Connectivity (5 issues, 5 done): OAuth client credentials flow merged (#56011, head a9c3e1f), token refresh merged (#56040), outbound signing merged (#56072), rate-limit handling merged (#56090), health-check endpoint merged (#56101). Review of #56090 took 4 rounds because of a disagreement about whether to retry on 503; resolved by retrying with the vendor's Retry-After header. Agent run 2026-10-22 produced the initial draft of #56101, Mihai rewrote the tests.

Milestone Entity sync (6 issues, 1 done, 3 in progress, 2 backlog): PLT-2231 asset pull merged (#56120). PLT-2232 asset push in progress, PR #56155 open, bugbot clean, waiting on Priya Natarajan's review since 2026-10-24. PLT-2233 conflict resolution in progress, no PR yet, Mihai working on the design doc (wip/plt2233-design.md, not shared). PLT-2234 location mapping in progress, blocked on PLT-2232. PLT-2235 and PLT-2236 (parts push and parts pull) backlog.

Milestone Hardening (3 issues, 0 done): PLT-2240 integration test suite against the vendor sandbox, PLT-2241 observability dashboards, PLT-2242 runbook. PLT-2240 is the one that matters for the health: the vendor sandbox at sandbox.vendorco.example has returned 503 since 2026-10-20 (9 days). Vendor support ticket VC-88213 opened 2026-10-21 by Mihai, last reply from the vendor 2026-10-27 said "escalated to the platform team, no ETA". Without the sandbox the integration tests can't run and the push path can't be validated end to end. Unit tests all pass. The connectivity milestone was validated against the sandbox before it went down.

Proposed mitigations discussed in #plt-vendor-sync on 2026-10-28 (Mihai, Priya, Tomas Lindqvist): (a) build a local stub of the vendor API from their OpenAPI spec and run the integration suite against it, estimated at 2 to 3 days by Tomas, and (b) ask the vendor for a second sandbox tenant through our account manager. Neither has been started. Priya proposed (a), Tomas is unsure it's worth it if the sandbox comes back this week, Mihai hasn't decided. Nobody has committed to a date for either.

No date has been proposed for when the sandbox will be back. The December 4 target has not been changed in Linear.

Other: Dana Okafor asked in Slack whether the parts milestones could be dropped from the first release; no answer yet, that would be a scope decision for the PM. Datadog shows p95 for the pull path at 420 ms against the sandbox before it went down, under the 500 ms budget.

Leadership asks: none raised so far. Possible ask: help escalating the vendor ticket through the partnership contact, if the sandbox is still down by Monday. Not decided whether to ask.
