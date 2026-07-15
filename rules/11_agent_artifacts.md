# Agent Artifacts

## Plans, designs, and reports live in `~/.ai/wip/` — never commit them

Working artifacts an agent produces to think, plan, or report are **not shippable code**. They go to `~/.ai/wip/` and never get committed to a git repo. This covers:

- Design docs and specs (`~/.ai/wip/<topic>-<date>.md`)
- Implementation plans (`~/.ai/wip/<topic>-plan-<date>.md`)
- Agent reports (via the `write-agent-report` skill → `~/.ai/wip/agent_reports/<agent>/...`)
- Prior-art / research scans (`~/.ai/wip/<topic>-prior-art-<date>.md`)
- Investigation scratchpads and pipeline state files

**Why:** fleet workers and subagents run with their cwd inside a product repo. A relative path like `wip/foo.md`, `design/foo.md`, or `plans/foo.md` lands in that repo and gets swept into a commit. That pollutes the repo with scratch nobody wants in history, and it fails review. Always use the absolute `~/.ai/wip/` path — never a repo-relative one.

**Rules for every agent, worker, and subagent:**

- Write plans/designs/reports to `~/.ai/wip/` using an absolute path (`$HOME/.ai/wip/...` or `~/.ai/wip/...`). Never a repo-relative `design/`, `plans/`, `wip/`, or `research/` path.
- Before `git add`/`git commit`, check that no plan/design/report/spec/scratch file is staged. If one is, it was written to the wrong place — move it to `~/.ai/wip/` and unstage it.
- If a task prompt tells you to "commit the design doc" or "commit the plan", treat it as "save it to `~/.ai/wip/`". The design/plan is the input to the next phase, not a repo artifact.
- Product code, tests, and changelogs still get committed as normal. This rule is only about the agent's own thinking/planning/reporting artifacts.
