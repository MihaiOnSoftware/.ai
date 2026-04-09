# INVEST Criteria for Slices

Each slice should satisfy INVEST (from the story splitting framework):

**I - Independent**: Can be implemented without being blocked by other slices. Some dependencies are unavoidable (slice 5 needs slice 1), but minimize coupling.

**N - Negotiable**: Could discuss different approaches to achieve the slice's goal. Not so detailed that implementation is prescribed.

**V - Valuable**: Delivers learning, risk mitigation, or actual functionality. Ask "what do we gain from completing this slice?"

**E - Estimable**: Can understand and assess the scope and complexity. If you can't gauge the complexity or understand what's involved, the slice is too vague or depends on unknown complexity.

**S - Small**: Roughly 1/8 to 1/4 of your velocity. Each slice should take hours, not days.

**T - Testable**: Has concrete success criteria. Not "works well" but "hash is deterministic", "cache key includes hash", etc.

## Applied Example

**Applying INVEST to this project's Slice 1**:
- ✅ Independent: Can be done first, no dependencies
- ✅ Negotiable: Could use different hashing algorithms, different cache key formats
- ✅ Valuable: Proves Sorbet introspection works (biggest risk)
- ✅ Estimable: Clear scope - single file creation, one method, basic tests - complexity is well understood
- ✅ Small: Single file creation, one method, basic tests
- ✅ Testable: "Hash is deterministic", "cache key includes hash"

If a slice violates INVEST, split it further or reorder.
