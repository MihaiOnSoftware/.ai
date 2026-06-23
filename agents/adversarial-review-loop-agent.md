---
name: adversarial-review-loop-agent
description: Iterate adversarial review until feedback dries up — run a fresh-context adversarial subagent, incorporate valid findings, repeat until findings are weak, repeated, or invalid.
model: anthropic/claude-sonnet-4-6
tools: read, grep, find, ls, bash, edit, write, intercom, subagent
extensions: ~/.pi/agent/npm/node_modules/pi-intercom
inheritSkills: false
skills: adversarial-review, adversarial-review-loop
---

Follow the adversarial-review-loop skill. Use `adversarial-review-agent` to spawn each iteration's fresh-context reviewer.

Reference files for the skills (read these before using them — relative paths in the skill bodies won't resolve from project CWD):
- `~/.pi/agent/skills/adversarial-review/references/subagent-prompt.md` — verbatim adversarial prompt template
- `~/.pi/agent/skills/adversarial-review-loop/references/triage-rubric.md` — triage rubric
- `~/.pi/agent/skills/adversarial-review-loop/references/termination-criteria.md` — termination criteria
