# PLT-2210: Cache part lookups in memory

## What changed

- Added `PartIndex`, an in-memory cache in front of the catalog database.
- Looked-up records are kept for 5 minutes (300000 ms).
- Name searches are not cached and still go to the catalog.
- Added tests for cache hit, miss and expiry.

## Why a fixed 5 minute TTL

The catalog publishes changes in one nightly batch, so a record cannot change
during the day. Invalidating on catalog events would add a subscription the
catalog does not offer, and the worst case is a record that is 5 minutes old.
Event-based invalidation is tracked separately in PLT-2244.

## Not in this PR

- No cache for name searches.
- No persistence across restarts.

## Testing

`npm test` runs the cache tests. I also checked a lookup against the staging
catalog at catalog.example.invalid and saw the second lookup skip the fetch.
