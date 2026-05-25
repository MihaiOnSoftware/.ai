# Example: investigation → issue comment + PR description

Investigation work doesn't always produce a `design/` doc. Often the output is a GitHub **issue comment** (the risk + evidence summary) plus a **PR description** (the change being made).

This example shows the shape, distilled from a real investigation (`flow-29306-upgrade-shopify_security_base-4`). The investigation phase ran across Observe, BigQuery, gem source via `gh api`, and three rounds of adversarial-subagent refutation. The output below is the distillation.

---

## Issue comment shape

Posted on `shop/issues#29306` (paraphrased structure, judgement calls stripped):

> **Risk assessment: path-traversal enforcement in `shopify_security_base` 4.0.0**
>
> ### What changes
> Version 4.0.0 of `shopify_security_base` raises `PathTraversalException` on any `Net::HTTP` request whose path contains `../` (or URL-encoded variants). Version 3.x logged-only.
>
> ### Production signal
> - **Observe** (`flow-production` dataset, 7-day window): 0 occurrences of the v3.x observe-mode log line `shopify_security_base.path_traversal.detected`.
> - **BigQuery** (`apps_and_developers.flow_config_field_values_v1` JOIN `shopify_flow.workflows_v1 WHERE is_active`): 24 workflows had URL config-field values containing `%2f` literals, all in query-parameter position. 0 workflows contained adjacent `..%2f` or `../` patterns.
> - The 24 false positives were surfaced by an adversarial-subagent pass on the initial query, which had used `LIKE '%..%2f%'` without requiring adjacency.
>
> ### Residual risk
> - **Liquid template variables**: a workflow author could template a `../` into the URL at runtime. We cannot enumerate Liquid template outputs exhaustively. Mitigation: ship observe-only first (PR 1, below), monitor for 7 days, enforce in PR 2.
> - The Rails 8.1.2 monkey-patch removal (deployed 2026-04-06) broke `Rails.event.notify` ingestion for ~2 weeks. Observe data older than that window may be incomplete.
>
> ### Recommendation
> Ship in two PRs:
> 1. Bump to 4.0.0 + register the gem's `http_request_allow_path_traversal_callback` to **log only** (no raise).
> 2. After 7 days of clean Observe data, flip the callback to raise.
>
> ### How this was investigated
> - Read the gem source for v3.1.7 (deployed) and v4.0.0 (target) via `gh api repos/Shopify/shopify_security_base/contents/...`.
> - Verified the callback API in v4.0.0 ships via `Net::HTTPGenericRequest#exec` monkey-patch (not `Net::HTTP#request`).
> - 3 rounds of adversarial-subagent refutation on the "0 active workflows affected" claim.

---

## PR description shape (PR 1, the observe-only ship)

Following the Flow team's WHAT / WHY / Testing / Review-tip template:

> ### What
> Bump `shopify_security_base` from 3.1.7 to 4.0.0. Register a callback that **logs** path-traversal detections without raising.
>
> ### Why
> v4.0.0 raises `PathTraversalException` by default. We want one week of observe-only signal in production before enabling enforcement — see [issue #29306](https://github.com/shop/issues/issues/29306) for the risk assessment.
>
> ### Testing
> - Unit: new spec asserts the registered callback gets called on a `../` path and does **not** raise.
> - Manual: `bin/rails runner` with a crafted `Net::HTTP.get(URI('http://example.com/../etc/passwd'))` → confirmed log line in `log/development.log`, no exception.
>
> ### Review tip
> The single load-bearing change is `config/initializers/shopify_security_base.rb`:
> ```ruby
> config.http_request_allow_path_traversal_callback = ->(path) do
>   Rails.event.notify("shopify_security_base.path_traversal.detected", path: path)
>   true # allow — observe only
> end
> ```
> All other changes are version-bump churn (Gemfile.lock, sorbet/rbi).

---

## What this excerpt demonstrates

- **Investigation outputs land in PR/issue threads**, not a separate design doc.
- **The issue comment is structured like a design doc** — "what changes", "production signal", "residual risk", "recommendation", "how this was investigated" — same skeleton as a design's "what exists today / non-goals / open questions / accepted simplifications."
- **Judgement calls are stripped.** "Risk + evidence it won't materialize" is the framing, not "this is fine."
- **The methodology itself goes in the comment.** "3 rounds of adversarial-subagent refutation" tells future readers how much skepticism the conclusion survived.
- **Known gaps are surfaced**, not buried. The Rails event-ingestion gap and the Liquid template gap both get explicit mention.
- **Two-PR staged delivery** when the investigation surfaces residual risk. Don't try to ship one big change when observe-mode-first → enforce-later is available.
- **The PR description includes "Review tip"** — the load-bearing change is one stanza of code; the rest is churn. Tell the reviewer where to look.
