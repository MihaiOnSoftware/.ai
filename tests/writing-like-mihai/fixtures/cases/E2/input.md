Thread: "Webhook retries for customers with long maintenance windows", 11 messages, 2026-10-21 to 2026-10-28

Renée Caron (Support), 10-21: three escalations in September from customers whose webhook endpoints were down for 1 to 2 hours during maintenance. Events were lost after our retries gave up. Asked whether we can retry longer.

Mihai, 10-21: current policy is 5 attempts over about 43 minutes. Will look at extending. Asked how many customers have windows longer than 45 minutes.

Renée, 10-22: doesn't have numbers, guesses a handful, will ask the CSM team.

Priya Natarajan, 10-22: proposed 7 attempts over about 3h42m (0s, 30s, 2m, 10m, 30m, 1h, 2h). Also proposed respecting Retry-After on 429.

Tomas Lindqvist, 10-23: fine with 7 attempts. Flagged that a customer hard-down for a day gets 7 requests per event instead of 5, asked whether anyone looked at the highest-volume customers. Nobody had.

Mihai, 10-23: will check the top 5 customers by webhook volume before shipping. Agreed on 7 attempts and 429 handling. Ticket PLT-488.

Renée, 10-24: asked whether customers will be told. Suggested a changelog entry.

Priya, 10-24: thinks it's an internal reliability change and doesn't need a changelog.

Mihai, 10-27: no decision yet on announcing. Will raise it with the PM. PR is up, PLT-488, review in progress with Tomas.

Renée, 10-28: CSM team got back: 11 customers have declared maintenance windows over 45 minutes, longest is 3 hours. Asked when it ships.

Mihai, 10-28: no ship date yet, depends on review and on the top-5 volume check. Will update the thread. In the meantime Support can tell customers that longer retries are in progress and that events are retried for about 43 minutes today.

Dead-letter replay (letting customers replay failed events from the UI) was mentioned by Tomas on 10-23 as a better long-term fix; everyone agreed it's a product feature and out of scope for PLT-488.
