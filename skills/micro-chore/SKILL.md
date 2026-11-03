---
name: micro-chore
description: Perform ONE piece of administrative work a repo requires for a PR (e.g. a changelog entry, a CODEOWNERS line, a docs update, a regenerated file), with no behaviour and no test, then stage it for the caller to commit. Use for a PR bundle's closing items inside a TDD slice. Not for code changes (micro-tdd, micro-refactor) or validation fixes (micro-fix).
license: MIT
metadata:
  category: tdd
---

Perform a single chore exactly as instructed and leave it staged.

**Input**: One chore instruction, for example "add the changelog entry for the new package describing the engine leaf module move, ticket <key>".

**Output**: The chore done, staged, lint and format clean, and a short report.

## Workflow

1. **Read the rules**: use skill `load-rules`.
2. **Find the repo's own tooling for the chore** before writing anything by hand: a changelog CLI, a CODEOWNERS convention visible in the file, a generator script in the package manifest. The closest `AGENTS.md` names them when they exist. Use the tool; hand-edit only when no tool exists.
3. **Do exactly the one chore.** Touch nothing else.
4. **Check**: run the repo's formatter and lint on the touched paths, and any validator the chore has (a changelog validate script or equivalent). Fix what they flag inside the touched files.
5. **Stage** the touched files with `git add <paths>`.
6. **Report** with the `write-agent-report` skill (`agent_name: micro-chore-agent`): the instruction, the tool or file used, the paths staged, the checks run with their results, status. Return only the report path.

## Stop and report instead of improvising when

- The instruction is ambiguous about what the artifact should say (which project, which ticket, which scope).
- The repo's tool refuses the input (unknown project, invalid key) and the fix is not in the instruction.
- Doing the chore would require changing code or tests.
