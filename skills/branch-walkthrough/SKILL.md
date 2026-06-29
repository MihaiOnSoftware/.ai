---
name: branch-walkthrough
description: Use when the user asks to interactively walk through branch or uncommitted code changes chunk by chunk before or during review. Presents actual diffs and waits for feedback; not a defect-finding review unless the user asks evaluative questions.
license: MIT
metadata:
  category: analysis
---

Present code changes in digestible conceptual chunks, one at a time, so the user can review, ask questions, request edits, approve, or skip each chunk.

## Scope Boundaries

This skill is a walkthrough skill, not a general code-review or implementation workflow.

**Do:**
- Show actual diff hunks, not paraphrases.
- Group related changes into focused chunks.
- Add enough context for the user to understand why each chunk exists.
- Wait for feedback after every chunk.

**Do not:**
- Hunt for defects unless the user asks an evaluative question about the code.
- Load code-review skills unless the user asks for review judgment, risk assessment, bug finding, security concerns, or similar evaluation.
- Modify files unless the user directly requests a change.
- Present all chunks at once.

When the user does ask an evaluative question, delegate that question to a subagent and tell the subagent to load relevant code-review skills first. This keeps the walkthrough focused and avoids flooding the main context with investigation output.

## Inputs and Output

**Input**: Optional branch name or `uncommitted`. Defaults to uncommitted changes.

**Output**: An interactive walkthrough containing:
- Sequentially numbered chunks.
- Actual diff output for each chunk.
- Brief purpose and file context.
- A final summary with counts for approved, skipped, and modified chunks.

## Workflow

### Step 1: Determine What to Walk Through

- If the user specifies a branch, compare that branch to its parent/base branch.
- If the user says `uncommitted`, walk through uncommitted changes.
- If unspecified, default to uncommitted changes.

### Step 2: Gather Changes

For uncommitted changes:

```bash
git status
git diff HEAD
```

For branch changes, do **not** assume `main` is the parent branch. Use the bundled `get-parent-branch.sh` script (located in the `scripts/` directory alongside this SKILL.md file) to determine the real parent. Run it from inside the repo directory and capture its output as the parent branch, then use that in `git diff` and `git log` with three-dot range syntax against the target branch.

### Step 3: Ask for Context

Before presenting chunks, ask:

> Before I walk through the changes, is there any additional context I should take into account? For example: background, constraints, decisions to highlight, or areas of focus.

If the user provides context, use it in chunk explanations. If they say no or ask to proceed, continue using the diff alone.

### Step 4: Group Changes into Chunks

Group changes by concept, not mechanically by file. Good grouping strategies:

1. **Feature/task**: Changes that serve the same behavior.
2. **File purpose**: Tests, implementation, config, or docs.
3. **Dependency**: Foundation changes before callers.
4. **Scope**: Small focused changes separate from larger refactors.

Authoritative chunk checklist:

- Each chunk must be independently understandable.
- Each chunk must have one clear purpose.
- Each chunk must include actual diff output.
- Each chunk should be 30 to 40 lines when possible.
- Each chunk must not exceed 50 diff lines. Split large hunks rather than paraphrasing or compressing them.
- Do not precompute or announce the total chunk count. Number chunks sequentially as you present them.

### Step 5: Present One Chunk

Use this structure:

````markdown
## Chunk 1: [Conceptual description]

**Purpose**: [Why this change exists]
**Files affected**:
- [path]

```diff
[actual diff output]
```

**Context**: [Optional. Mention user-provided context, patterns, decisions, or gotchas only when useful.]

Ready for your feedback on this chunk:
- Type "approve" or "next" to continue
- Ask questions about the changes
- Request modifications
- Type "skip" to move to next chunk without approval
````

Preserve file paths, line numbers, `+` and `-` prefixes, context lines, and `@@` markers.

For an example, see [examples/chunk-presentation.md](examples/chunk-presentation.md).

### Step 6: Handle Feedback

**Approve / next**: Move to the next chunk.

**Question about what the code does**: Answer directly if it only requires explaining the visible chunk.

**Evaluative question about correctness, risk, bugs, security, maintainability, or review judgment**: Delegate to a subagent. The subagent prompt must start with this line verbatim:

```text
Before answering, search your available skills for a code review skill and load it.
```

Then include the current chunk's diff and the user's question. Present the subagent's findings directly and stay on the current chunk until the user approves or skips it.

**Direct change request**: Make only the requested change, show the updated diff, and wait for approval.

**Skip**: Move to the next chunk without marking the current one approved. Track it as skipped.

### Step 7: Complete the Walkthrough

After all chunks are reviewed, summarize:

```markdown
## Walkthrough Complete

**Summary**:
- Total chunks: N
- Approved: X
- Skipped: Y
- Modified: Z

**Files reviewed**: [list all files]
**Total changes**: +X -Y lines
```

## Anti-Patterns

- Assuming `main` is the parent branch. Always run the bundled `get-parent-branch.sh` script (in the skill's `scripts/` directory) to find the real parent.
- Paraphrasing code changes instead of showing actual diffs.
- Letting chunks exceed 50 lines.
- Announcing a total number of chunks before you have worked through them.
- Skipping the context question.
- Loading review skills or doing defect-finding before the user asks an evaluative question.
- Editing files without a direct change request.
- Rushing through multiple chunks without feedback.
