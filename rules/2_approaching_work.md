# General Coding Methodology for LLM Agents

## The Four-Phase Structure

### 1. ANALYZE 🔍

**Purpose**: Understand the problem space and requirements before coding.

**Activities:**

- **Understand the requirements** clearly and completely
- **Investigate the existing codebase** to understand patterns and constraints
- **Identify potential challenges** and edge cases upfront
- **Research dependencies** and their requirements
- **Assess complexity** and plan accordingly

**Investigation Techniques:**

- Use semantic search to understand how similar problems are solved
- Examine existing code patterns and conventions
- Check for special format requirements or constraints
- Look for related tests or examples
- Understand the broader system architecture

**Key Questions:**

- What are the exact requirements?
- How is this pattern implemented elsewhere?
- What are the dependencies and their constraints?
- What could go wrong and how would I detect it?
- Are there existing examples I can learn from?

### 2. PLAN 📋

**Purpose**: Create a structured approach with clear milestones and success criteria.

**Activities:**

- **Create TODO list** with specific, actionable items
- **Break down complex work** into manageable phases
- **Identify dependencies** and order of operations
- **Plan testing strategy** appropriate to the task
- **Define success criteria** for each phase

**Planning Principles:**

- Make each TODO item specific and measurable
- Order tasks by dependencies and logical flow
- Include testing and validation in the plan
- Anticipate where investigation might be needed
- Plan for cleanup and quality improvements

**Key Principle**: **Tests come first** in almost all scenarios. When making production code changes, write tests that demonstrate the desired behavior before implementing. When working with existing code, write tests to verify current behavior before making changes.

### 3. EXECUTE ⚡

**Purpose**: Implement the solution with disciplined problem-solving.

**Execution Principles:**

- **Follow the plan** but be ready to adapt based on discoveries
- **When stuck**: STOP, INVESTIGATE, don't guess
- **Make incremental progress** with frequent validation
- **Document discoveries** that affect the plan
- **Ask for help** when investigation reaches limits

**Investigation Techniques:**

- **Add debug output** to understand execution flow
- **Check error messages** carefully for clues
- **Examine working examples** for patterns
- **Trace through system** to understand data flow
- **Use tools** (grep, semantic search) to find relevant code
- **Test hypotheses** with small, focused changes

**When to Modify Production Code:**

- ✅ **Explicit bug fixes**: When you're specifically tasked with fixing a confirmed bug
- ✅ **Feature additions**: When adding new functionality
- ✅ **Refactoring**: When improving code structure
- ✅ **Debug output**: Temporarily for investigation (then remove)
- ❌ **Assumptions**: Don't change production code based on guesses
- ❌ **Working code**: If it works in production, understand why first
- ❌ **Incidental issues**: If you encounter unexpected behavior while working on something else, investigate first and ask before changing

### 4. CLEANUP (Quality Phase) ✨

**Purpose**: Apply quality standards and ensure maintainable, professional code.

Follow the steps outlined in the cleanup user rules.

## Success Patterns

### Quality Implementation

- **Incremental development** with frequent validation
- **Comprehensive testing** that catches real bugs
- **Clean, maintainable code** that follows conventions
- **Proper error handling** and edge case coverage
- **Clear documentation** and self-explaining code

## Conclusion

This methodology emphasizes **disciplined investigation** over quick fixes, **systematic planning** over ad-hoc development, and **quality standards** over rushed completion. The key insight is that **taking time to understand problems deeply** leads to better solutions and valuable learning about system architecture.

The four-phase structure provides a framework that scales from simple bug fixes to complex feature development, always maintaining focus on understanding, quality, and systematic progress.
