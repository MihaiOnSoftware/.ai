# Example: Thought Process for Splitting a Task

**Question**: How do I split automatic schema hash implementation?

**Answer**:
1. What's the simplest proof? → Hash Task only, no children
2. What infrastructure do we need? → Rails config, initializer for hot reload
3. What's the next increment? → Add direct children (Port, ConfigField)
4. What complexity comes next? → Arrays and Unions (T::Array[ConfigField])
5. What completes the solution? → Recursion (find SelectConfigFieldOption)
6. What makes it maintainable? → Sealed subclass auto-discovery

**Result**: 6 slices, each building on the previous, each testable, each delivering value.
