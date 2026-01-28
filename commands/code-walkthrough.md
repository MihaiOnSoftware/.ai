---
description: Walk through code changes chunk by chunk with context
argument-hint: [branch-name | uncommitted]
---

Present code changes in digestible conceptual "chunks" one by one, allowing review, questions, and approval.

## What This Command Does

**Input**: Optional branch name or "uncommitted" (defaults to uncommitted)

**Output**: Interactive walkthrough of code changes with context

**Presents**:
- Actual code changes (not paraphrased)
- Relevant agent reports for context
- Changes grouped into conceptual chunks (MAX 50 lines each)
- One chunk at a time, waiting for feedback

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

Keep this context in mind when presenting chunks - reference specific reports when they explain why changes were made.

### Step 4: Group Changes into Conceptual Chunks

Analyze changes and group into logical units:

**Grouping strategies**:
1. **By feature/task**: Changes related to same feature
2. **By file purpose**: Tests together, implementation together
3. **By dependency**: Changes that depend on each other
4. **By scope**: Small focused changes vs larger refactors

**Each chunk should**:
- Be independently understandable
- Have clear purpose
- Fit on screen (30-40 lines ideal, MAX 50 lines)
- Include related changes together

**CRITICAL RULE**: Chunks MUST NOT exceed 50 lines. If a chunk exceeds 50 lines, you MUST break it into multiple smaller chunks. Never paraphrase or compress changes to fit into fewer chunks.

### Step 5: Present First Chunk

**Important**: Number chunks sequentially (1, 2, 3...) as you present them. Do NOT pre-calculate or display the total number of chunks upfront.

For each chunk, present:

**1. Context Header**:
```
## Chunk 1: [Conceptual Description]

**Purpose**: [Why this change exists]
**Files affected**: [List of files]
**Related agent reports**: [Links to relevant reports if any]
```

**Note**: Just number chunks sequentially (1, 2, 3...). Don't predict or display the total - you'll report the final count in the summary.

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
Ready for your feedback on this chunk:
- Type "approve" or "next" to continue
- Ask questions about the changes
- Request modifications
- Type "skip" to move to next chunk without approval
```

### Step 6: Handle User Feedback

**If user approves/says next**:
- Move to next chunk
- Repeat Step 5 with next chunk

**If user asks questions**:
- Answer based on code and context
- Show additional code if helpful
- Stay on current chunk until approved

**If user requests changes**:
- Make the requested changes
- Show updated diff
- Wait for approval

**If user says skip**:
- Move to next chunk without marking as approved
- Note which chunks were skipped

### Step 7: Complete Walkthrough

After all chunks reviewed, present summary:

```
## Walkthrough Complete

**Summary**:
- Total chunks: N
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
- Summary of each chunk that was presented
- Questions asked and answers provided
- Modifications requested and made
- Final status (approved/skipped) for each chunk
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

### Keep Chunks Digestible
- 30-40 lines ideal, MAX 50 lines per chunk to fit on screen
- Group related changes together
- Break up large changes into logical sections
- Don't split atomic changes across chunks

### Interactive Approach
- **Wait for feedback** after each chunk
- Don't rush through all chunks at once
- Allow time for questions and discussion
- Make requested changes before moving on

## Examples

### Example Chunk Presentation

```
## Chunk 1: Add validation for user input

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

Ready for your feedback on this chunk:
- Type "approve" or "next" to continue
- Ask questions about the changes
- Request modifications
- Type "skip" to move to next chunk without approval
```

## Success Criteria

- ✅ Changes grouped into logical, digestible chunks
- ✅ Actual diff output shown (not paraphrased)
- ✅ Relevant agent reports loaded and referenced
- ✅ Extra context provided where helpful
- ✅ Interactive: waits for feedback after each chunk
- ✅ Allows questions, modifications, and approval
- ✅ Completes with summary of what was reviewed

## Anti-Patterns to AVOID

**DO NOT**:
- Paraphrase code changes - show actual diffs
- Rush through all chunks without waiting for feedback
- Show changes without context
- Make chunks larger than 50 lines (break them up even if atomic)
- Pre-determine how many chunks you'll need (let content decide)
- Skip loading agent reports
- Present all changes at once

**DO**:
- Show actual diff output with proper formatting
- Wait for user feedback after each chunk
- Provide context from agent reports
- Keep chunks digestible and focused
- Group related changes together
- Allow interactive discussion
