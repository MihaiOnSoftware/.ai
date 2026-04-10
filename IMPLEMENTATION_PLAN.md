# Implementation Plan: Shared Install Helpers for Downstream Repos

## Problem

`.ai` and `.shopify-ai` (and any future namespace repos) duplicate all install boilerplate: logging, symlink management, path definitions, and install/uninstall scripts. `.ai`'s install scripts each inline their own copy of `is_correct_symlink`/`create_symlink`. `.shopify-ai` extracted those into `symlink_helpers.sh` but diverged slightly. Every script also duplicates `-f` flag parsing.

Additionally, `.shopify-ai` has a Claude Code skill discovery bug — it symlinks a `shopify/` subdirectory, but Claude only looks one level deep (`~/.claude/skills/<name>/SKILL.md`), so the skills are invisible.

## End State

`.shopify-ai/install.sh` becomes roughly:

```bash
source "$HOME/.ai/lib/logging.sh"
~/.ai/lib/install_skills.sh shopify "$SCRIPT_DIR/skills"
~/.ai/lib/install_agents.sh shopify "$SCRIPT_DIR/agents"
```

Most of `.shopify-ai/lib/` gets deleted. The Claude skill discovery bug gets fixed for free.

## Splitting Pattern

**SIMPLE/COMPLEX** — start with low-level helpers, build up to the simpler high-level command (agents: uniform symlinks), then tackle the complex one (skills: Claude per-skill quirk).

## Slices

### Slice 1: Extract `symlink_helpers.sh`, deduplicate within `.ai`

**Goal**: Eliminate the 4+ copy-pasted definitions of `is_correct_symlink`/`create_symlink` across `.ai`'s own install scripts. Foundation for everything else.

**Approach**:
- Create `lib/symlink_helpers.sh` containing `is_correct_symlink`, `create_symlink`, `uninstall_symlink`, and `validate_source_dir`
- Include counter variables (`COUNT_CREATED`, `COUNT_CORRECT`, `COUNT_WARNING`) initialized with defaults
- Source `logging.sh` from the same directory so consumers only need to source one file for symlink operations
- `logging.sh` stays as its own file, unchanged
- Refactor `.ai`'s install scripts (`install_agents.sh`, `install_rules.sh`, `install_scripts.sh`, `install_pi.sh`) to source `symlink_helpers.sh` instead of defining their own copies
- Similarly refactor the uninstall scripts to use `uninstall_symlink`
- Leave `install_skills.sh` alone for now — its Claude per-skill loop is special
- Have `.ai`'s install process symlink both `lib/logging.sh` and `lib/symlink_helpers.sh` to `~/.ai/lib/`

**Tests**:
- `./uninstall.sh && ./install.sh`: all symlinks created correctly
- `./install.sh` again: idempotent, reports "already exists"
- `./uninstall.sh`: all symlinks removed cleanly
- `~/.ai/lib/logging.sh` and `~/.ai/lib/symlink_helpers.sh` exist after install
- `source ~/.ai/lib/symlink_helpers.sh` works from an external script

### Slice 2: Refactor `paths.sh` to expose tool-level config root directories

**Goal**: Make `paths.sh` a source of truth for where each tool stores its config, without baking in resource types or namespaces. Currently `PI_DIR` exists but Claude and OpenCode don't have equivalents.

**Approach**:
- Add root config directory variables: `CLAUDE_DIR` (~/.claude), `OPENCODE_DIR` (~/.config/opencode). `PI_DIR` already exists.
- Redefine the existing full-path variables in terms of these roots (e.g. `CLAUDE_AGENTS_PATH` becomes `$CLAUDE_DIR/agents/generic`)
- No behavior change — every existing variable keeps its current value, just derived differently

**Tests**:
- `./uninstall.sh && ./install.sh`: identical behavior
- `source lib/paths.sh && echo $CLAUDE_DIR` prints `~/.claude`

### Slice 3: Create `agent_helpers.sh` with `install_agents`/`uninstall_agents` functions

**Goal**: First high-level helper. Agents are the simple case — uniform directory symlinks across all targets.

**Approach**:
- Create `lib/agent_helpers.sh` that sources `symlink_helpers.sh` and `paths.sh`
- Define agent-specific base paths internally: `CLAUDE_AGENTS_BASE=$CLAUDE_DIR/agents`, `OPENCODE_AGENTS_BASE=$OPENCODE_DIR/agents`, `PI_AGENTS_BASE=$PI_DIR/agents`
- Define `install_agents <namespace> <source_dir>` that validates the source dir, constructs `<base>/<namespace>` for each target, and calls `create_symlink` for each
- Define `uninstall_agents <namespace> <source_dir>` similarly

**Tests**:
- Source `agent_helpers.sh` and call `install_agents generic "$AGENTS_DIR"`: correct symlinks created
- `uninstall_agents` removes them cleanly

### Slice 4: Centralize force mode as environment variable

**Goal**: Eliminate the duplicated `-f` / `getopts` parsing across all install scripts.

**Approach**:
- Change `create_symlink` in `symlink_helpers.sh` to read a global `FORCE_MODE` variable (defaulting to `false`) instead of taking it as a third parameter
- Each repo's top-level `install.sh` is the only place that parses `-f` and exports `FORCE_MODE`
- Remove the `getopts` blocks from all the individual install scripts

**Tests**:
- `./install.sh -f`: force mode propagates, wrong symlinks get fixed
- `./install.sh` (no flag): `FORCE_MODE` defaults to `false`, wrong symlinks produce warnings

### Slice 5: Reusable `install_agents.sh` / `uninstall_agents.sh` wrapper scripts

**Goal**: Thin script wrappers that any repo can call with a namespace and source directory.

**Approach**:
- Refactor `lib/install_agents.sh` to accept `<namespace> <source_dir>` as positional arguments, source `agent_helpers.sh`, call `install_agents`
- Refactor `lib/uninstall_agents.sh` similarly
- Update `.ai`'s top-level `install.sh` to call `lib/install_agents.sh generic "$AGENTS_DIR"`
- Remove the agent full-path variables from `paths.sh` — that knowledge now lives in `agent_helpers.sh`
- Expose at `~/.ai/lib/`

**Tests**:
- `./uninstall.sh && ./install.sh`: agent symlinks at all three `generic` namespace targets
- `~/.ai/lib/install_agents.sh shopify /tmp/test-agents`: creates symlinks at all three `shopify` namespace paths
- Missing arguments: prints usage and exits with error

### Slice 6: `skill_helpers.sh` + `install_skills.sh` / `uninstall_skills.sh` with Claude per-skill handling

**Goal**: The complex case. Claude Code only discovers skills one level deep, so skills need individual symlinks into the flat `~/.claude/skills/` directory. OpenCode and Pi use the normal directory symlink approach.

**Approach**:
- Create `lib/skill_helpers.sh` that sources `symlink_helpers.sh` and `paths.sh`
- Define skill-specific base paths: `CLAUDE_SKILLS_BASE=$CLAUDE_DIR/skills`, `OPENCODE_SKILLS_BASE=$OPENCODE_DIR/skills`, `PI_SKILLS_BASE=$PI_DIR/skills`
- `install_skills <namespace> <source_dir>`:
  - For Claude: iterate each subdirectory containing a `SKILL.md`, create individual symlink at `$CLAUDE_SKILLS_BASE/<skill_name>` (flat, not namespaced)
  - For OpenCode and Pi: single directory symlink at `<base>/<namespace>`
- `uninstall_skills <namespace> <source_dir>`:
  - For Claude: iterate entries in `$CLAUDE_SKILLS_BASE`, remove symlinks pointing into `<source_dir>`
  - For OpenCode and Pi: `uninstall_symlink` on the namespace directory
- Create `lib/install_skills.sh` and `lib/uninstall_skills.sh` as thin wrappers accepting `<namespace> <source_dir>`
- Refactor `.ai`'s top-level scripts to call `lib/install_skills.sh generic "$SKILLS_DIR"`
- Remove skills-related path variables from `paths.sh`
- Expose at `~/.ai/lib/`

**Tests**:
- `./uninstall.sh && ./install.sh`: Claude gets individual per-skill symlinks, OpenCode and Pi get directory symlinks
- `~/.ai/lib/install_skills.sh shopify /path/to/.shopify-ai/skills`: Claude gets individual symlinks for each skill directly in `~/.claude/skills/`
- Uninstall removes only symlinks pointing into the correct source directory
- Skill directory without `SKILL.md` is skipped for Claude

### Slice 7: Install shared lib files to `~/.ai/lib/`

**Goal**: Make shared helpers discoverable by downstream repos at a well-known location.

**Approach**:
- Create `lib/install_lib.sh` that symlinks shared files from `.ai`'s `lib/` to `~/.ai/lib/`: `logging.sh`, `symlink_helpers.sh`, `paths.sh`, `agent_helpers.sh`, `skill_helpers.sh`, `install_agents.sh`, `uninstall_agents.sh`, `install_skills.sh`, `uninstall_skills.sh`
- Create `lib/uninstall_lib.sh`
- Add both to `.ai`'s top-level `install.sh` / `uninstall.sh` — runs first

**Tests**:
- `./install.sh`: all shared files exist at `~/.ai/lib/` as symlinks
- `./uninstall.sh`: all `~/.ai/lib/` symlinks removed
- `source ~/.ai/lib/skill_helpers.sh` works from an external script

### Slice 8: Refactor `.ai` to consume from `~/.ai/lib/`

**Goal**: Dogfood the shared helpers by having `.ai`'s own install call scripts from `~/.ai/lib/` instead of relative paths. Proves the interface works before any downstream repo depends on it.

**Approach**:
- Lib install step (Slice 7) runs first
- Refactor `.ai`'s top-level `install.sh` to call `~/.ai/lib/install_agents.sh generic "$AGENTS_DIR"`, `~/.ai/lib/install_skills.sh generic "$SKILLS_DIR"`, etc.
- Refactor `uninstall.sh` to call from `~/.ai/lib/`, then uninstall the lib symlinks last
- Install scripts for rules, scripts, and pi (not yet converted to the helper pattern) continue using local paths

**Tests**:
- `./uninstall.sh && ./install.sh`: all symlinks created, same end state as before
- Delete `~/.ai/lib/` manually, run `./install.sh`: lib gets recreated first, then everything else succeeds
- `./uninstall.sh`: everything removed, `~/.ai/lib/` emptied last

## After This

`.shopify-ai` can be independently refactored to source from `~/.ai/lib/` and delete its own `lib/`. That work happens in the `.shopify-ai` repo.
