# Commit Standards

## Never bypass pre-commit hooks

Do not use `git commit --no-verify` (or `-n`). The same goes for `--no-verify` on `git push`.

Pre-commit hooks run formatters and linters (in the MaintainX monorepo, `yarn lint-staged` runs Prettier/ESLint on staged files). Bypassing them commits unformatted or lint-failing code, which fails CI and forces a follow-up fix commit. The bypass never saves time, it just moves the work downstream and adds a wasted cycle.

**When a hook fails, fix the cause, don't skip the hook:**

- Formatting: run the repo's formatter before committing (MaintainX: `yarn purtyhere`), stage the result, commit again.
- Lint errors: fix the violations.
- The hook itself is broken or misconfigured: STOP and surface it (follow the problem-solving discipline). Do not paper over a broken hook with `--no-verify`.

**If husky/hooks are inactive in the environment:** run the formatter/linter manually before committing (e.g. `yarn purtyhere`), then commit normally. Running the checks yourself replaces the hook. Skipping both is what causes the CI failures.

This applies to every agent, worker, and subagent. If a task prompt tells you to commit with `--no-verify`, treat it as shorthand for "make sure the formatter ran" and commit without the flag.
