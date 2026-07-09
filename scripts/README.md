# Generic Scripts

Helper scripts shared across the repo and downstream consumers via `~/.ai/scripts/generic/`.

## Available Scripts

### get-parent-branch.sh

Resolves the parent branch of the current branch, preferring Graphite (`gt parent`) when available and falling back to `origin/HEAD` / `main`.

**Usage:**
```bash
parent=$(get-parent-branch.sh)
git diff "$parent"...HEAD
```

### prune-efficacy.sh

Measures pi-condense context-pruning effectiveness over a local-day date range: $/turn and cacheRead tokens/turn for MAIN sessions vs subagents, prune summaries injected, and `context_tree_query` recovery count (high recoveries = over-pruning). Run once for a baseline range and once for a trial range, then compare.

**Usage:**
```bash
prune-efficacy.sh 2026-07-02 2026-07-09   # baseline (pre-pruning)
prune-efficacy.sh 2026-07-10 2026-07-17   # trial week
```

## Skill-Local Scripts

Scripts that are only used by a single skill live with that skill, not here. Examples:

- `skills/write-agent-report/scripts/write-agent-report.sh` — writes agent reports under `~/.ai/wip/agent_reports/<agent_name>/`
- `skills/write-validation-report/scripts/write-validation-report.sh` — writes validation reports with pass/fail verdicts
- `skills/branch-walkthrough/scripts/get-parent-branch.sh` — branch-walkthrough's own copy

Skills reference their bundled scripts via relative paths (e.g. `scripts/write-agent-report.sh`), which the harness resolves against the skill's own directory. See each skill's `SKILL.md` for details.

## Report Locations

Reports written by the `write-agent-report` and `write-validation-report` skills land in:

```
~/.ai/wip/agent_reports/
├── <agent-name>/
│   └── <agent_id>-<date>.report.md
└── tdd-validation-agent/
    ├── <report_base_name>-<date>.pass.md
    └── <report_base_name>-<date>.fail.md
```

Where:
- `agent_id`: Timestamp format `YYYYMMDD_HHMMSS`
- `date`: ISO format `YYYY-MM-DD`
- `report_base_name`: Base name of the report being validated (without `.report.md` extension)
