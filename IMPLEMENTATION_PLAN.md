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

### ✅ Slice 3: Create `agent_helpers.sh` with `install_agents`/`uninstall_agents` functions

**Status**: Complete (commits b0712c5, b6886fe)

**What was done**:
- Created `lib/agent_helpers.sh` with `install_agents <source_dir>` and `uninstall_agents <source_dir>`
- Per-file iteration, no namespace parameter
- Refactored `install_agents.sh` and `uninstall_agents.sh` to use the functions

### ✅ Slice 5: Reusable `install_agents.sh` / `uninstall_agents.sh` wrapper scripts

**Status**: Complete (commits be6143f, 03a7e25)

**What was done**:
- Made scripts accept `<source_dir>` as positional argument
- Removed `AGENTS_DIR` from `paths.sh`
- Exposed `paths.sh`, `agent_helpers.sh`, `install_agents.sh`, `uninstall_agents.sh` at `~/.ai/lib/`

### ✅ Slice 6: `skill_helpers.sh` + `install_skills.sh` / `uninstall_skills.sh` with Claude per-skill handling

**Status**: Complete (commits 2372560, ed65a6b, 985e9a2)

**What was done**:
- Created `lib/skill_helpers.sh` with `install_skills <namespace> <source_dir>` and `uninstall_skills <namespace> <source_dir>`
- Claude: per-skill flat symlinks. OpenCode/Pi: namespace directory symlinks.
- Refactored `install_skills.sh`/`uninstall_skills.sh` to use the functions with positional args
- Removed `install_pi.sh`/`uninstall_pi.sh` (skills handled by skill_helpers)
- Removed `SKILLS_DIR`, `OPENCODE_SKILLS_PATH`, `PI_SKILLS_PATH` from `paths.sh`
- Exposed `skill_helpers.sh`, `install_skills.sh`, `uninstall_skills.sh` at `~/.ai/lib/`

### ~~Slice 7: Expand `~/.ai/lib/`~~ (absorbed into Slices 5 and 6)

### ✅ Slice 8: Refactor `.ai` to consume from `~/.ai/lib/`

**Status**: Complete (commit c0ea96d)

**What was done**:
- `install.sh` calls `~/.ai/lib/install_agents.sh` and `~/.ai/lib/install_skills.sh` instead of relative paths
- `uninstall.sh` calls `~/.ai/lib/uninstall_agents.sh` and `~/.ai/lib/uninstall_skills.sh`
- Lib install runs first, lib uninstall runs last
- Scripts/rules stay as relative paths (not yet converted)

### Slice 9: Flatten skill symlinking to per-skill for all targets

**Goal**: Make all skill targets use per-skill individual symlinks (like agents). Drop the namespace parameter.

**Approach**:
- Change `skill_helpers.sh`: all three targets iterate skill subdirs with `SKILL.md`, create individual symlinks (Claude already does this)
- Drop `<namespace>` from `install_skills`/`uninstall_skills` signatures
- Update `paths.sh`: add `OPENCODE_SKILLS_DIR` and `PI_SKILLS_DIR`, remove `CLAUDE_SKILLS_DIR` (all three now use `*_SKILLS_DIR`)
- Update `install_skills.sh`/`uninstall_skills.sh` wrappers to take just `<source_dir>`
- Update `install.sh`/`uninstall.sh` callers
- Add old-style namespace directory symlink cleanup to uninstall (like agents did for `generic`)

**Tests**:
- `./uninstall.sh && ./install.sh`: all three targets get individual per-skill symlinks
- `ls ~/.claude/skills/`, `ls ~/.config/opencode/skills/`, `ls ~/.pi/agent/skills/` all show individual skill symlinks
- `./install.sh` again: idempotent
- `./uninstall.sh`: all removed, non-.ai entries untouched

## After This

`.shopify-ai` can be independently refactored to source from `~/.ai/lib/` and delete its own `lib/`. That work happens in the `.shopify-ai` repo.
