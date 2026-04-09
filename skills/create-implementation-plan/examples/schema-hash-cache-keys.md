# Example: Automatic Schema Hash for Cache Keys

Simplified plan for adding automatic schema hash to Rails cache keys (this project):

**Context**: Rails cache doesn't invalidate when Ruby class schemas change (new fields added). Need automatic detection.

```
Slice 1: Basic schema hash for Task only
Goal: Prove Sorbet introspection works, validate cache invalidation mechanism
Tests: Hash is deterministic, cache key includes hash, HACK workaround removed

Slice 2: Hot reload support
Goal: Make dev-friendly by supporting code reloading
Tests: Hash accessible via Rails.config, calculated during initialization
Note: Limited automated testing - requires manual verification

Slice 3: Discover direct child types
Goal: Catch changes to Task's immediate dependencies
Tests: Hash includes ConfigField/Port/ReturnField, hash changes when child field changes

Slice 4: Handle Array and Union types
Goal: Correctly extract types from complex type declarations
Tests: Extracts element type from T::Array[X], handles T.nilable(X)

Slice 5: Recursive type discovery
Goal: Complete the solution by discovering deeply nested types
Tests: Hash includes SelectConfigFieldOption (the original bug!), prevents infinite loops

Slice 6: Sealed subclass discovery
Goal: Zero maintenance when new ConfigField types added
Tests: Hash includes all ~20+ ConfigField subclasses, count matches expected
```

**What makes this excellent**:
- Slice 1 validates entire approach (biggest risk: does introspection work?)
- Each slice adds exactly one new concept (children, arrays, recursion, sealed classes)
- Each slice has concrete, testable success criteria
- Can stop after any slice and still have value
- Pattern: **SIMPLE/COMPLEX** - start with bare-bones (hash one class), layer on complexity
