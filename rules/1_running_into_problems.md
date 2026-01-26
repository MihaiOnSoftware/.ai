# Core Philosophy

**When problems arise, follow the discipline:**

1. **STOP** ⛔ - Don't throw code at the problem
2. **THINK** 🤔 - Analyze what's actually happening
3. **INVESTIGATE** 🔍 - Add debug output, trace through code, understand root cause
4. **ASK** ❓ - Request help when stuck (the human will return)

**Never:**

- ❌ Give up immediately after first failure
- ❌ Make random code changes hoping something works
- ❌ Assume without investigating
- ❌ Skip investigation steps when confused

**Problem-Solving Discipline:**

```
Problem Encountered
        ↓
    STOP ⛔
        ↓
    THINK 🤔
   What's actually happening?
        ↓
  INVESTIGATE 🔍
   Add debug output
   Trace through code
   Check similar examples
        ↓
   UNDERSTAND ✅
        ↓
   Implement Fix
        ↓
   Remove Debug Code
```

## Investigation Strategies

- **Add debug output** to understand execution flow
- **Check error messages** carefully for clues
- **Examine working examples** for patterns
- **Trace through system** to understand data flow
- **Use tools** (grep, semantic search) to find relevant code
- **Test hypotheses** with small, focused changes

## When to Ask for Help

- **After thorough investigation** when the root cause isn't clear
- **When multiple approaches** seem viable and you need direction
- **When assumptions need validation** from domain expertise
- **When stuck** despite following the investigation process
- **Before making significant changes** to unfamiliar systems
- **When explicit user instructions fail**, like using MCPs

## Cost of Compromises vs. Asking

**Compromising when stuck costs MORE**:
- User must review, reject, and wait for you to redo it correctly
- The work gets done twice (yours wrong, then right after asking)

**Asking when stuck costs LESS**:
- User provides guidance once, work done right the first time
- No wasted review-reject-redo cycle

The work needs to be correct regardless. Compromising just adds a wasteful cycle before eventually asking anyway.

## Success Patterns

### Effective Investigation

- **Follow the error trail** systematically
- **Understand before fixing** - don't guess
- **Use existing patterns** as guides
- **Make minimal, focused changes** during investigation
- **Document discoveries** for future reference

### Successful Collaboration

- **Ask specific questions** when seeking help
- **Share investigation results** to provide context
- **Follow guidance** and learn from feedback
- **Document lessons learned** for future work
- **Maintain professional standards** throughout

## Conclusion

The key insight is that **taking time to understand problems deeply** leads to better solutions and valuable learning about system architecture.
