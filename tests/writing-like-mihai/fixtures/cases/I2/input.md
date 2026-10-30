Context

Integrators calling GET /parts?updatedSince=... get a 500 when the timestamp has more than three fractional-second digits. Reproduced with 2026-10-20T10:00:00.1234Z. Three support tickets since October 15.

What to do

Accept up to nine fractional digits and truncate to milliseconds, matching what POST /parts already does. Add a unit test for the parser with 0, 3, 6 and 9 digits.

Out of scope

Changing the documented format. The docs already say ISO 8601 with optional fractional seconds.
