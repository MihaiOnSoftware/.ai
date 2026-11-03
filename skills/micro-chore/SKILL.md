---
name: micro-chore
description: Perform ONE repository chore that has no behaviour and no test, such as a changelog entry, a CODEOWNERS line, a docs update or a regenerated file, then stage it for the caller to commit. Use for a PR bundle's closing items inside a TDD slice. Not for code changes (micro-tdd, micro-refactor) or validation fixes (micro-fix).
license: MIT
metadata:
  category: tdd
---

Perform a single chore exactly as instructed and leave it staged.

**Input**: One chore instruction, for example "add a changelog entry for `@mx-tooling/rest-graphql-coverage` describing the engine leaf module move, Linear API-911".

**Output**: The chore done, staged, lint and format clean, and a short report.

## Workflow

1. **Read the rules**: use skill `load-rules`.
2. **Find the repo's own tooling for the chore** before writing anything by hand: a changelog CLI (`yarn changelog-add`, with `--list-projects` for the project name), a CODEOWNERS convention visible in the file, a generator script in `package.json`. The closest `AGENTS.md` names them when they exist. Use the tool; hand-edit only when no tool exists.
3. **Do exactly the one chore.** Touch nothing else.
4. **Check**: run the repo's formatter and lint on the touched paths, and any validator the chore has (`yarn changelog-validate` or equivalent). Fix what they flag inside the touched files.
5. **Stage** the touched files with `git add <paths>`.
6. **Report** with the `write-agent-report` skill (`agent_name: micro-chore-agent`): the instruction, the tool or file used, the paths staged, the checks run with their results, status. Return only the report path.

## Stop and report instead of improvising when

- The instruction is ambiguous about what the artifact should say (which project, which Linear key, which scope).
- The repo's tool refuses the input (unknown project, invalid key) and the fix is not in the instruction.
- Doing the chore would require changing code or tests.
