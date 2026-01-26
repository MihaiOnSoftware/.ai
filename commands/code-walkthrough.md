---
description: Walk through code changes bite by bite with context
argument-hint: [branch-name | uncommitted]
---

Present code changes in digestible conceptual "bites" one by one, allowing review, questions, and approval.

## What This Command Does

**Input**: Optional branch name or "uncommitted" (defaults to uncommitted)

**Output**: Interactive walkthrough of code changes with context

**Presents**:
- Actual code changes (not paraphrased)
- Relevant agent reports for context
- Changes grouped into conceptual bites
- One bite at a time, waiting for feedback

## Workflow

### Step 1: Determine What to Review

**If branch specified**: Compare branch to its parent/base branch
**If "uncommitted" specified**: Review uncommitted changes
**Default**: Uncommitted changes

### Step 2: Gather Changes

**For uncommitted changes**:
```bash
# Get status
git status

# Get full diff with context
git diff HEAD
```

**For branch changes**:
```bash
# Use helper script to get parent branch (handles Graphite stacks)
parent_branch=$(~/.ai/scripts/generic/get-parent-branch.sh <branch-name>)

# Get branch diff compared to parent
git diff ${parent_branch}...<branch-name>

# Get commit log for context
git log ${parent_branch}...<branch-name> --oneline
```

### Step 3: Load Agent Reports

**ALWAYS** load agent reports from `~/.ai/wip/agent_reports/`:

```bash
# List all agent reports sorted by date (most recent first)
find ~/.ai/wip/agent_reports/ -name "*.report.md" -type f -exec ls -lt {} + | head -20
```

**Read recent reports** to gather context:
- TDD agent reports for test implementations
- Task extraction reports for structural changes
- Validation reports for quality checks
- Any other agent reports that might be relevant

**Parse reports** to understand:
- What work was done
- What decisions were made
- What patterns were followed
- What context is relevant to changes

Keep this context in mind when presenting bites - reference specific reports when they explain why changes were made.

### Step 4: Group Changes into Conceptual Bites

Analyze changes and group into logical units:

**Grouping strategies**:
1. **By feature/task**: Changes related to same feature
2. **By file purpose**: Tests together, implementation together
3. **By dependency**: Changes that depend on each other
4. **By scope**: Small focused changes vs larger refactors

**Each bite should**:
- Be independently understandable
- Have clear purpose
- Fit on screen (aim for 30-40 lines per bite)
- Include related changes together

**IMPORTANT**: The total number of bites is NOT fixed. If you're presenting a bite and realize it's too long (>40 lines), you MUST break it into smaller bites and adjust the total count. Never paraphrase or compress changes to fit a predetermined bite count.

### Step 5: Present First Bite

For each bite, present:

**1. Context Header**:
```
## Bite 1/N: [Conceptual Description]

**Purpose**: [Why this change exists]
**Files affected**: [List of files]
**Related agent reports**: [Links to relevant reports if any]
```

**Note**: N (total bite count) can change as you present. If a bite is too long, break it up and adjust N.

**2. The Actual Changes**:
Show the actual diff output, preserving:
- File paths
- Line numbers
- Added lines (+ prefix)
- Removed lines (- prefix)
- Context lines (no prefix)
- Diff markers (@@)

**Format**:
```diff
diff --git a/path/to/file.rb b/path/to/file.rb
--- a/path/to/file.rb
+++ b/path/to/file.rb
@@ -10,5 +10,8 @@
 context line
-removed line
+added line
 context line
```

**3. Additional Context** (if helpful):
- What patterns this follows
- Why specific approaches were chosen
- How this relates to other changes
- Any gotchas or important details

**4. Wait for Feedback**:
```
Ready for your feedback on this bite:
- Type "approve" or "next" to continue
- Ask questions about the changes
- Request modifications
- Type "skip" to move to next bite without approval
```

### Step 6: Handle User Feedback

**If user approves/says next**:
- Move to next bite
- Repeat Step 5 with next bite

**If user asks questions**:
- Answer based on code and context
- Show additional code if helpful
- Stay on current bite until approved

**If user requests changes**:
- Make the requested changes
- Show updated diff
- Wait for approval

**If user says skip**:
- Move to next bite without marking as approved
- Note which bites were skipped

### Step 7: Complete Walkthrough

After all bites reviewed, present summary:

```
## Walkthrough Complete

**Summary**:
- Total bites: N
- Approved: X
- Skipped: Y
- Modified: Z

**Files reviewed**: [List all files]
**Total changes**: +X -Y lines
```

### Step 8: Write Agent Report

Use `/generic:write-agent-report` to document the walkthrough:

**Report should include**:
- What changes were reviewed (branch or uncommitted)
- Summary of each bite that was presented
- Questions asked and answers provided
- Modifications requested and made
- Final status (approved/skipped) for each bite
- Any important context or decisions discussed

This creates a record of the code review session for future reference.

## Presentation Guidelines

### Show Actual Changes
- **ALWAYS** show the actual diff output
- **NEVER** paraphrase code changes
- Include enough context lines (3-5 lines around changes)
- Preserve all diff markers and formatting

### Extra Context is Good
- Explain **why** changes were made
- Reference agent reports when relevant
- Point out patterns or conventions followed
- Highlight important details

### Keep Bites Digestible
- 30-40 lines per bite to fit on screen
- Group related changes together
- Break up large changes into logical sections
- Don't split atomic changes across bites

### Interactive Approach
- **Wait for feedback** after each bite
- Don't rush through all bites at once
- Allow time for questions and discussion
- Make requested changes before moving on

## Examples

### Example Bite Presentation

```
## Bite 1/3: Add validation for user input

**Purpose**: Ensure user input is sanitized before processing
**Files affected**:
- lib/user_input.rb
- test/user_input_test.rb
**Related agent reports**: micro-tdd-agent/20250126_143022-2025-01-26.report.md

### Changes:

diff --git a/lib/user_input.rb b/lib/user_input.rb
--- a/lib/user_input.rb
+++ b/lib/user_input.rb
@@ -10,5 +10,12 @@ class UserInput
   def process(input)
     return nil if input.nil?
+    return nil if input.empty?
+
+    sanitized = input.strip
+    sanitized = sanitized.gsub(/[<>]/, '')
+
+    sanitized
   end
 end

diff --git a/test/user_input_test.rb b/test/user_input_test.rb
--- a/test/user_input_test.rb
+++ b/test/user_input_test.rb
@@ -15,4 +15,14 @@ class UserInputTest < Minitest::Test
     assert_nil result
   end
+
+  def test_strips_whitespace
+    result = UserInput.new.process("  hello  ")
+    assert_equal "hello", result
+  end
+
+  def test_removes_html_brackets
+    result = UserInput.new.process("<script>alert('xss')</script>")
+    assert_equal "scriptalert('xss')/script", result
+  end
 end

### Context:

This follows the validation pattern used throughout the codebase - sanitize at the boundary before processing. The micro-tdd-agent report shows this was developed test-first, with each test driving the implementation.

The HTML bracket removal prevents basic XSS while still allowing the content through (the actual HTML removal happens in a later processing stage).

Ready for your feedback on this bite:
- Type "approve" or "next" to continue
- Ask questions about the changes
- Request modifications
- Type "skip" to move to next bite without approval
```

## Success Criteria

- ✅ Changes grouped into logical, digestible bites
- ✅ Actual diff output shown (not paraphrased)
- ✅ Relevant agent reports loaded and referenced
- ✅ Extra context provided where helpful
- ✅ Interactive: waits for feedback after each bite
- ✅ Allows questions, modifications, and approval
- ✅ Completes with summary of what was reviewed

## Anti-Patterns to AVOID

**DO NOT**:
- Paraphrase code changes - show actual diffs
- Rush through all bites without waiting for feedback
- Show changes without context
- Make bites too large (>40 lines unless atomic change requires it)
- Treat the total bite count as fixed - adjust it if needed
- Skip loading agent reports
- Present all changes at once

**DO**:
- Show actual diff output with proper formatting
- Wait for user feedback after each bite
- Provide context from agent reports
- Keep bites digestible and focused
- Group related changes together
- Allow interactive discussion
