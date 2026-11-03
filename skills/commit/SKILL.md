---
name: commit
description: Create a commit following message rules and writing style guidelines. Also the single place an orchestrator without bash sends branch, amend and reset instructions.
license: MIT
metadata:
  category: git
---

Read current changes and create a proper commit following commit message rules and writing style guidelines.

**Does NOT**:
- Run tests
- Run cleanup commands
- Modify code
- Stage selectively (uses what is staged; stages everything when nothing is)

## Workflow

### Step 1: Read Rules

Read `~/.ai/rules/6_writing_style.md` for writing style guidelines.

Apply these commit message rules:

- Only mention things that are different from the last commit
- Do not mention intermediary steps or changes that were added and then removed within the same commit session
- Focus on the final state, not the process of getting there
- Keep explanation of what was done short, quick, and direct
- Only add additional context beyond the first line if explaining why or if something is not easily inferred from the code



### Step 2: Examine Changes

`git status`, then `git diff --cached` (or `git diff HEAD` when nothing is staged), then `git log -3 --oneline` for the repo's message style. If there is nothing to commit, stop and report "nothing to commit".

### Step 3: Determine What to Stage

**If files are already staged**:
- Use staged files as-is

**If no files are staged**:
- Stage all modified/new files: `git add -A`

### Step 4: Draft Commit Message

Apply the Step 1 rules and `6_writing_style.md` (active voice, plain words):

```
[First line: concise description of what changed]

[Optional body: additional context if needed]
```

### Step 5: Create Commit

Create the commit using heredoc format for proper formatting:

```bash
git commit -m "$(cat <<'EOF'
[Commit message first line]

[Optional body]
EOF
)"
```

## Orchestrator instructions

Orchestrators without `bash` send every branch or history change here. `commit` is the default when the task names no instruction. Every other instruction carries the HEAD it expects; when `HEAD` differs, or a required SHA is missing, stop, return the actual SHAs (and `git status --porcelain` when the tree is dirty), and change nothing.

| Instruction | Task wording | What you do |
|---|---|---|
| `commit` | (none) | Steps 1 to 5 above. Return `commit: <sha> <first line>`. |
| `prepare branch` | "prepare branch `<name>` at `<sha>`" | Require a clean tree. If `<name>` does not exist: require `HEAD` == `<sha>`, then `git switch -c <name>`. If it exists: require its tip == `<sha>`, then `git switch <name>`. Return `branch: <name>, tip: <sha>`. |
| `amend` | "amend `<head sha>` with the staged changes" | Require `HEAD` == `<head sha>`. `git commit --amend --no-edit`. Return the new SHA. |
| `reset` | "reset `--soft`\|`--hard` from `<head sha>` to `<sha>`" | Require `HEAD` == `<head sha>` and `<sha>` an ancestor of it. Run the reset. Return `HEAD` after. |

Never rebase, push, or touch a remote under any instruction.

## Anti-Patterns to AVOID

**DO NOT**:
- Make commits without examining the actual changes
- Write vague messages like "update files" or "fix issues"
- Bypass pre-commit hooks with `--no-verify`. If a hook fails, fix the cause (run the formatter/linter, e.g. `yarn purtyhere`) and commit again. See `~/.ai/rules/10_commit_standards.md`.

For a worked example session, see [examples/session.md](examples/session.md).

For good and bad commit message examples, see [examples/good-bad-messages.md](examples/good-bad-messages.md).
