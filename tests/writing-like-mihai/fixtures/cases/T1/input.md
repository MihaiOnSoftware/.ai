Facts for the parts lookup cache TSD (PLT-412)

- Problem: the public REST GET /parts/external/{externalId} endpoint resolves an external ID to a part by querying the parts table on every call. Integrators poll it in bulk during nightly syncs. In the last 30 days the p95 latency on that route was 640 ms and the parts table accounted for 38% of read IOPS on the primary during the 02:00-04:00 UTC window.
- Decision (agreed with Dana Okafor and Tomas Lindqvist on the API Platform team): add a read-through cache keyed by (organizationId, externalId) in front of the lookup, using the existing Redis cluster the gateway already uses for rate limiting. TTL 10 minutes. Invalidate on part update/delete via the existing PartUpdated and PartDeleted domain events.
- Alternatives considered and rejected:
  1. Add a covering index on parts(organization_id, external_id). Already exists; the cost is the read volume, not the plan.
  2. Serve from the read replica. Replica lag during the sync window has been measured at up to 9 seconds, and integrators write then immediately read.
  3. Materialized lookup table maintained by a worker. More moving parts than a cache with the same invalidation events.
- Non-goals: caching the list endpoint; caching any write path; changing the response shape.
- Genuinely open: whether the cache should be shared across the Assets and Locations external-ID endpoints in the same change or done per domain in follow-ups. Dana prefers per domain; Tomas is fine either way. No decision yet.
- No dates or milestones have been set for this work.
