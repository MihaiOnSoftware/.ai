src/lookup/part_index.ts:42 — major: the cache key ignores the catalog version, so a catalog update can serve stale part records until the TTL expires.
src/lookup/handlers/search.ts:17 — minor: the empty-result branch returns `null`, but the response schema declares an array.
src/lookup/normalize.ts:88 — nit: `tmp` is a vague name for the normalized part code.
src/lookup/part_index.ts:105 — minor: the expiry sweep has no test for entries that expire during a lookup.
test/lookup/part_index.test.ts:31 — nit: the three cache tests repeat the same setup and could share a helper.
