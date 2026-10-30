# parts-lookup

A small service that answers part lookups for the maintenance catalog.

## What it does

- Looks up a part record by catalog code.
- Searches part records by name.
- Keeps looked-up records in memory for a short time so repeated lookups skip the catalog database.

## Layout

- `src/lookup/part_index.ts`: the cache and the lookup entry points
- `src/lookup/normalize.ts`: code normalization and attribute merging
- `src/lookup/handlers/search.ts`: the search request handler
- `docs/lookup-spec.md`: the behavior the service promises
- `test/lookup/part_index.test.ts`: cache tests

## Running the tests

    npm test

## Ownership

Questions go to the catalog-platform channel. Tickets are tracked under PLT.
