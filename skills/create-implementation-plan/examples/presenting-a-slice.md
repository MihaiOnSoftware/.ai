# Example: Presenting a Single Slice

Here's what presenting a single slice should look like:

---

**Slice 1: Basic schema hash for Task only**

**Goal**: Prove Sorbet introspection works and validate the cache invalidation mechanism. This is the critical risk - if we can't introspect class schemas, the entire approach fails.

**Approach**:
- Create a SchemaHasher class that uses Sorbet's decorator introspection to access the props defined on a class
- Extract field names and their type signatures from the Task class
- Sort these signatures alphabetically to ensure deterministic ordering
- Generate a SHA-256 hash from the concatenated signatures
- Modify the Task cache key generation to include this schema hash
- Remove the existing HACK workaround that manually increments version numbers

**Tests**:
- Hash is deterministic: calling hash_schema twice on the same class returns the same hash
- Cache key includes the schema hash in the expected format
- Adding a new field to Task changes the hash value
- Removing the HACK workaround doesn't break existing functionality

---

*[Wait for user approval before presenting Slice 2]*
