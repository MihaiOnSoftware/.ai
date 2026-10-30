# Parts lookup: behavior spec

## Part codes

- Part codes are matched without regard to case.
- Codes are normalized to upper case before lookup.
- The normalized code is also the cache key.
- Leading and trailing whitespace is ignored.

## Cache

- A looked-up record is cached for 5 minutes.
- An expired record is fetched again on the next lookup.
- A code with no record is never cached.

## Search

- A name search returns the matching part records.
- A search with no matches returns an empty list.
- Search results are not cached.

## Errors

- A failing catalog fetch is reported to the caller unchanged.
- The service does not retry a failed fetch.
