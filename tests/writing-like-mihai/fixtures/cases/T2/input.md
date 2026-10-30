PLT-488 webhook retry investigation, running notes

Started by pulling the last 14 days of webhook delivery logs from the gateway (query in ~/wip/plt488-query.sql, took 3 tries because the index on delivered_at isn't used when you filter by status first, note to self). 2.1M deliveries total. 1.9% ended in a terminal failure after retries. Of those terminal failures 71% are HTTP 5xx from the customer endpoint, 22% are connection timeouts, 7% are 4xx (mostly 410 Gone and 404).

Current retry policy (webhookDispatcher.ts, the RETRY_SCHEDULE const): 5 attempts at 0s, 30s, 2m, 10m, 30m. So a customer outage longer than ~43 minutes loses the event. Checked with Renée Caron (Support) and she confirmed the three escalations in September were all customers with maintenance windows of 1 to 2 hours. She didn't have exact numbers for how many customers that affects, she guessed "a handful" but said she'd check with the CSM team.

Looked at how the Assets export worker does retries for comparison (exportWorker.ts): exponential backoff with jitter up to 6 hours, 10 attempts, and it persists the attempt count on the job row. Different shape because it's a job queue, not an outbound HTTP call, but the backoff curve itself is reusable.

Spent a while (too long honestly) tracing why the dispatcher doesn't already persist attempt count. It does, in webhook_deliveries.attempt_count, it's just that RETRY_SCHEDULE is a fixed array and the code indexes into it, so extending the window is a one-line schedule change plus making the last element repeat.

Proposed decision, talked through with Tomas Lindqvist and Priya Natarajan on Tuesday: extend the schedule to 8 attempts ending around 4 hours (0s, 30s, 2m, 10m, 30m, 1h, 2h, 4h is approximately 7h43m total, Priya suggested dropping the 4h step to keep it under 4 hours, so 0s, 30s, 2m, 10m, 30m, 1h, 2h = 3h42m total, 7 attempts). Tomas and Priya both ok with the 7-attempt version. Keep 4xx as terminal immediately except 429, which should respect Retry-After. This is agreed.

Also considered: dead-letter the terminal failures into a table customers can replay from the UI. Everyone likes it but it's a product feature with UI work, not this ticket. Parking it. Considered making the schedule per-customer configurable: no demand for it, rejected.

Risk: 7 attempts over 3h42m means a customer endpoint that is hard-down for a day will absorb 7 requests per event instead of 5. With 2.1M deliveries per 14 days that's fine in aggregate, but a single customer with a high event volume could see a burst when they come back up. Didn't measure the worst case per-customer volume. Should probably check the top 5 customers by webhook volume before shipping. Not blocking.

Risk 2: the 429 Retry-After handling doesn't exist today, it's new code and needs tests. Small.

Open: do we announce the change to customers? Renée thinks yes via the changelog, Priya thinks it's an internal reliability change. Not decided.

Open: the dedup key. If the schedule changes while deliveries are in flight, the in-flight ones keep the old schedule because the index is persisted. Fine, but worth a line in the PR description. Not actually open, just noting it.

Note to self: the log query is slow, don't rerun it without the status filter.
