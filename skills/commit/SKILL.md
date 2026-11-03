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

Guard first: never commit agent scratch artifacts (`~/.ai/rules/11_agent_artifacts.md`). Plans, design docs, specs, agent reports, prior-art scans and investigation scratchpads belong in `~/.ai/wip/`, never in a project repo:

```bash
git status --short | grep -iE '(^|/)(wip|plans?|design|research)/|\.report\.md$|-(plan|prior-art)-[0-9]{4}' || echo "no scratch artifacts detected"
```

On a match, stop and surface it; the file should be moved to `~/.ai/wip/` and left untracked. Proceed only when the tree is free of scratch artifacts, or the user confirms a match is a legitimate repo file.

Then: if files are already staged, use them as-is; otherwise `git add -A` and re-run the guard against `git diff --cached --name-only`.

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

Stack branches are managed with `gh stack` (GitHub CLI extension; `gh extension install github/gh-stack`, Git 2.36+, `git config rerere.enabled true`). Always use the non-interactive forms below; `gh stack view --json` is how you read the stack.

| Instruction | Task wording | What you do |
|---|---|---|
| `commit` | (none) | Steps 1 to 5 above. Return `commit: <sha> <first line>`. |
| `prepare branch` | "prepare branch `<name>` at `<sha>`, base `<base branch>`" | Require a clean tree. If `<name>` is already in the stack: `gh stack checkout <name>`. Else if no stack exists: require `HEAD` == `<sha>`, then `gh stack init <name>` (add `--base <base branch>` when it is not the default branch). Else: require `HEAD` == `<sha>` and that it is the stack's top, then `gh stack add <name>`. In every case, afterwards require the current branch == `<name>` and `HEAD` == `<sha>` (`init` and `add` adopt a pre-existing branch of that name, which may sit elsewhere). Return `branch: <name>, tip: <sha>`. |
| `amend` | "amend `<head sha>` with the staged changes" | Require `HEAD` == `<head sha>`. `git commit --amend --no-edit`. Return the new SHA. |
| `reset` | "reset `--soft`\|`--hard` from `<head sha>` to `<sha>`" | Require `HEAD` == `<head sha>` and `<sha>` an ancestor of it. Run the reset. Return `HEAD` after. |
| `restack` | "restack above `<branch>` at `<head sha>`; old tips `<branch: sha, …>`" | Require the current branch == `<branch>` and `HEAD` == `<head sha>`. `gh stack rebase --upstack --no-trunk`. On exit 3 (conflict): `gh stack rebase --abort`, return the conflicting files, change nothing else. On success return `gh stack view --json` and, per rewritten branch, `git range-diff <old parent tip>..<old tip> <new parent tip>..<new tip>` so the caller can see which commits changed (`=`) or did not. |

Never push, open PRs, or touch a remote under any instruction (`gh stack rebase --no-trunk` does not fetch).

## Anti-Patterns to AVOID

**DO NOT**:
- Make commits without examining the actual changes
- Write vague messages like "update files" or "fix issues"
- Bypass pre-commit hooks with `--no-verify`. If a hook fails, fix the cause (run the formatter/linter, e.g. `yarn purtyhere`) and commit again. See `~/.ai/rules/10_commit_standards.md`.

For a worked example session, see [examples/session.md](examples/session.md).

For good and bad commit message examples, see [examples/good-bad-messages.md](examples/good-bad-messages.md).
