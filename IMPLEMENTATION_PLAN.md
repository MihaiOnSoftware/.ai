# Implementation Plan: Shared Install Helpers for Downstream Repos

## Problem

`.ai` and `.shopify-ai` (and any future namespace repos) duplicate all install boilerplate: logging, symlink management, path definitions, and install/uninstall scripts. `.ai`'s install scripts each inline their own copy of `is_correct_symlink`/`create_symlink`. `.shopify-ai` extracted those into `symlink_helpers.sh` but diverged slightly. Every script also duplicates `-f` flag parsing.

Additionally, `.shopify-ai` has a Claude Code skill discovery bug — it symlinks a `shopify/` subdirectory, but Claude only looks one level deep (`~/.claude/skills/<name>/SKILL.md`), so the skills are invisible.

## End State

`.shopify-ai/install.sh` becomes roughly:

```bash
source "$HOME/.ai/lib/logging.sh"
~/.ai/lib/install_skills.sh shopify "$SCRIPT_DIR/skills"
~/.ai/lib/install_agents.sh "$SCRIPT_DIR/agents"
```

Most of `.shopify-ai/lib/` gets deleted. The Claude skill discovery bug gets fixed for free.

## Splitting Pattern

**SIMPLE/COMPLEX** — start with low-level helpers, build up to the simpler high-level command (agents: per-file symlinks), then tackle the complex one (skills: Claude per-skill quirk, OpenCode/Pi directory symlinks).

## Slices

### ✅ Slice 1: Extract `symlink_helpers.sh`, deduplicate within `.ai`

**Status**: Complete (commits 3957859, e791378, 938f3c4, f8ac13e)

**What was done**:
- Created `lib/symlink_helpers.sh` with `is_correct_symlink`, `create_symlink`, `uninstall_symlink`, `validate_source_dir`
- `create_symlink` reads global `FORCE_MODE` (not a parameter) — force mode centralization done here
- Refactored all install scripts (agents, rules, scripts, pi, commands) to source it
- Refactored all uninstall scripts to source it
- `install.sh` exports `FORCE_MODE` via environment, removed `-f` flag passing to sub-scripts
- Removed `getopts` from all sub-scripts
- Created `lib/install_lib.sh`/`lib/uninstall_lib.sh` to symlink `logging.sh` and `symlink_helpers.sh` to `~/.ai/lib/`

### ✅ Slice 2: Refactor `paths.sh` to expose tool-level config root directories

**Status**: Complete (commit af4620a)

**What was done**:
- Added `CLAUDE_DIR` (~/.claude) and `OPENCODE_DIR` (~/.config/opencode) root variables
- Redefined all sub-paths in terms of these roots
- `PI_DIR` already existed

### ✅ Slice 3.0: Flatten agent symlinking to individual files

**Status**: Complete (commits b6a4252, 765e945)

**What was done**:
- Changed Claude and OpenCode from directory symlinks (`agents/generic`) to per-file symlinks (individual `.md` files directly in `agents/`)
- Matches Pi pattern (changed separately in 7cd3fdc)
- Removed agent handling from `install_pi.sh`/`uninstall_pi.sh` — agents fully handled by `install_agents.sh`/`uninstall_agents.sh`
- Replaced `CLAUDE_AGENTS_PATH`/`OPENCODE_AGENTS_PATH` with `CLAUDE_AGENTS_DIR`/`OPENCODE_AGENTS_DIR` in `paths.sh`
- Uninstall cleans up old-style `generic` directory symlinks

### ~~Slice 4: Centralize force mode~~ (done in Slice 1)

### Slice 3: Create `agent_helpers.sh` with `install_agents`/`uninstall_agents` functions

**Goal**: Extract agent install/uninstall logic into reusable functions that downstream repos can call.

**Approach**:
- Create `lib/agent_helpers.sh` that sources `symlink_helpers.sh` and `paths.sh`
- Define `install_agents <source_dir>`: validates source dir, iterates `*.md` files, creates individual symlinks in `CLAUDE_AGENTS_DIR`, `OPENCODE_AGENTS_DIR`, and `PI_AGENTS_DIR`
- Define `uninstall_agents <source_dir>`: iterates entries in each target dir, removes symlinks pointing into `<source_dir>`
- No namespace parameter — agent names are assumed unique across repos

**Tests**:
- Source `agent_helpers.sh` and call `install_agents "$AGENTS_DIR"`: correct per-file symlinks created in all three targets
- `uninstall_agents` removes only symlinks pointing into the given source dir

### Slice 5: Reusable `install_agents.sh` / `uninstall_agents.sh` wrapper scripts

**Goal**: Thin script wrappers that any repo can call with a source directory.

**Approach**:
- Refactor `lib/install_agents.sh` to accept `<source_dir>` as a positional argument, source `agent_helpers.sh`, call `install_agents`
- Refactor `lib/uninstall_agents.sh` similarly
- Update `.ai`'s top-level `install.sh` to call `lib/install_agents.sh "$AGENTS_DIR"`
- Remove agent target dir variables from `paths.sh` — that knowledge now lives in `agent_helpers.sh`
- Expose at `~/.ai/lib/`

**Tests**:
- `./uninstall.sh && ./install.sh`: per-file agent symlinks in all three targets
- `~/.ai/lib/install_agents.sh /tmp/test-agents`: creates per-file symlinks in all three targets
- Missing arguments: prints usage and exits with error

### Slice 6: `skill_helpers.sh` + `install_skills.sh` / `uninstall_skills.sh` with Claude per-skill handling

**Goal**: The complex case. Claude Code only discovers skills one level deep, so skills need individual symlinks into the flat `~/.claude/skills/` directory. OpenCode and Pi use directory symlinks with a namespace.

**Approach**:
- Create `lib/skill_helpers.sh` that sources `symlink_helpers.sh` and `paths.sh`
- `install_skills <namespace> <source_dir>`:
  - For Claude: iterate each subdirectory containing a `SKILL.md`, create individual symlink at `$CLAUDE_SKILLS_DIR/<skill_name>` (flat, not namespaced)
  - For OpenCode: single directory symlink at `$OPENCODE_SKILLS_DIR/<namespace>`
  - For Pi: single directory symlink at `$PI_SKILLS_DIR/<namespace>`
- `uninstall_skills <namespace> <source_dir>`:
  - For Claude: iterate entries in `$CLAUDE_SKILLS_DIR`, remove symlinks pointing into `<source_dir>`
  - For OpenCode and Pi: `uninstall_symlink` on the namespace directory
- Skills keep the `<namespace>` parameter because OpenCode and Pi use namespace subdirectories (unlike agents which are flat)
- Create `lib/install_skills.sh` and `lib/uninstall_skills.sh` as thin wrappers accepting `<namespace> <source_dir>`
- Refactor `.ai`'s top-level scripts to call `lib/install_skills.sh generic "$SKILLS_DIR"`
- Remove skills-related path variables from `paths.sh` — knowledge lives in `skill_helpers.sh`
- Expose at `~/.ai/lib/`

**Tests**:
- `./uninstall.sh && ./install.sh`: Claude gets individual per-skill symlinks, OpenCode and Pi get directory symlinks
- `~/.ai/lib/install_skills.sh shopify /path/to/.shopify-ai/skills`: Claude gets individual symlinks for each skill directly in `~/.claude/skills/`
- Uninstall removes only symlinks pointing into the correct source directory
- Skill directory without `SKILL.md` is skipped for Claude

### Slice 7: Expand `~/.ai/lib/` with all shared files

**Goal**: Make all shared helpers discoverable by downstream repos at `~/.ai/lib/`.

**Note**: `install_lib.sh`/`uninstall_lib.sh` already exist from Slice 1, symlinking `logging.sh` and `symlink_helpers.sh`. This slice expands them.

**Approach**:
- Update `lib/install_lib.sh` to also symlink: `paths.sh`, `agent_helpers.sh`, `skill_helpers.sh`, `install_agents.sh`, `uninstall_agents.sh`, `install_skills.sh`, `uninstall_skills.sh`
- Update `lib/uninstall_lib.sh` to remove them

**Tests**:
- `./install.sh`: all shared files exist at `~/.ai/lib/` as symlinks
- `./uninstall.sh`: all `~/.ai/lib/` symlinks removed
- `source ~/.ai/lib/skill_helpers.sh` works from an external script

### Slice 8: Refactor `.ai` to consume from `~/.ai/lib/`

**Goal**: Dogfood the shared helpers by having `.ai`'s own install call scripts from `~/.ai/lib/` instead of relative paths. Proves the interface works before any downstream repo depends on it.

**Approach**:
- Lib install step (Slice 7) runs first
- Refactor `.ai`'s top-level `install.sh` to call `~/.ai/lib/install_agents.sh "$AGENTS_DIR"`, `~/.ai/lib/install_skills.sh generic "$SKILLS_DIR"`, etc.
- Refactor `uninstall.sh` to call from `~/.ai/lib/`, then uninstall the lib symlinks last
- Install scripts for rules, scripts, and pi (not yet converted to the helper pattern) continue using local paths

**Tests**:
- `./uninstall.sh && ./install.sh`: all symlinks created, same end state as before
- Delete `~/.ai/lib/` manually, run `./install.sh`: lib gets recreated first, then everything else succeeds
- `./uninstall.sh`: everything removed, `~/.ai/lib/` emptied last

## After This

`.shopify-ai` can be independently refactored to source from `~/.ai/lib/` and delete its own `lib/`. That work happens in the `.shopify-ai` repo.
