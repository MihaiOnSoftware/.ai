# Example: The Same Feature Cut by Layer and Cut Vertically

Task: let API clients set an `externalId` on a resource when creating it (POST) and change or clear it later (PATCH), behind a feature flag, rejecting a value another resource already uses.

## Layer cut (what to avoid)

**Slice 1: Schema.** Add `externalId` to the request and response schemas and regenerate types. "Stands alone": the build is green and requests carrying the field no longer get an unknown-field 400. The field is silently discarded.

**Slice 2: Persistence.** Teach the create and update mutations to store the field and detect conflicts. "Stands alone": unit tests on the mutations pass. No request can reach them with the field.

**Slice 3: Handlers.** Wire POST and PATCH to pass the field through, gated by the flag. The plan's own words: "the slice a client can observe".

Every slice is green. Nothing the task promised works until the end. Stopping after slice 2 delivers nothing; a review comment on slice 1's schema after slice 3 exists reopens all three. The plan reads as WORKFLOW STEPS, but the steps are architectural layers, and the justification offered ("a consumer can't be exercised until the producer exists") is a dependency inside a slice, not a reason for a slice.

## Vertical cut

**Slice 1: POST stores an externalId.** Goal: a flagged client can create a resource with an `externalId` and read it back. The implementer builds, in order, the request-schema field, the create mutation's storage of it, and the handler pass-through, because each is needed by the next; those are items inside the slice, not slices. Tests: a flagged POST with the field returns it in the body; an unflagged POST ignores it; the field round-trips through a GET.

**Slice 2: POST rejects a duplicate externalId.** Goal: the conflict rule. Tests: a second POST with the same value gets the conflict response; a different value succeeds.

**Slice 3: PATCH changes or clears the externalId.** Goal: the update path, reusing slice 1's schema and storage. Tests: PATCH with a new value replaces it; PATCH with null clears it; the conflict rule from slice 2 applies.

Each slice makes one promised behaviour work through the boundary the task names (the REST endpoint). Slice 1 proves the risky assumption (the field survives the schema, mutation and handler chain) through the smallest usable behaviour rather than through the mutation in isolation. The stack can stop after any slice and have delivered something a client can use.

## The difference in one sentence

The layer cut asks "what has to exist before the next piece can be built"; the vertical cut asks "what works for the caller after this slice that did not before", and puts the first question's answer inside the slice.
