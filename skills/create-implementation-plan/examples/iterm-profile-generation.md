# Example: iTerm Profile Generation

Excellent plan structure for dynamic iTerm profile generation:

```
1. Create a new profile that's a copy of the current default (no colour changes, no auto switch, overrides existing generated profiles)
2. Allow the user to pass a colour preset name and use it when creating the profile
3. Add shell integration to automatically switch to the profile based on a path that's passed in
4. Include worktree name in profile name and badge text
5. Find the current worktree if no path is passed in and use that
6. Allow for multiple generated profiles (don't override, add to existing)
7. Persist which preset was assigned to which worktree (so re-running doesn't change it)
8. Pick a random colour preset from a list if none is passed in
9. Check other profiles when deciding colour preset so there aren't clashes (don't reuse until we've used all available)
10. List/view command to see generated profiles (optional - we'll see if iTerm's UI is sufficient)
11. Remove/cleanup command (optional - we'll see if needed)
```

**What makes this excellent**:
- Slice 1 proves the core mechanism (profile creation) works
- Each slice adds one new capability
- Early slices deliver value even if later slices are skipped
- Optional features clearly marked (slices 10-11)
- Each slice is testable and demoable
- Natural progression from simple to complex

**Pattern analysis**:
- **SIMPLE/COMPLEX**: Slice 1 is bare-bones profile creation. Slices 2-9 add sophistication.
- **OPERATIONS**: Slices 1-9 are "create/configure", slice 10 is "read/list", slice 11 is "delete".
- **BUSINESS RULES**: Slice 2 (manual color) → slice 8 (random color) → slice 9 (avoid clashes) adds progressively smarter behavior.
- **VARIATIONS IN DATA**: Slice 3 (path-based switching) → slice 5 (auto-detect worktree) handles different input types.

Notice how multiple patterns can apply simultaneously. Good plans often combine patterns.
