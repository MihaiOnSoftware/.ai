Files changed in PR #56155 (parts-lookup service):
- src/lookup/part_index.ts: cache part records by catalog id with a 5 minute TTL
- src/lookup/handlers/search.ts: serve exact-id queries from the cached index
- test/lookup/part_index.test.ts: cover cache hit, miss and expiry
Behavior: exact-id searches skip the database on a cache hit; fuzzy searches are unchanged.
