# Shared Install Helpers — Migration Guide for Downstream Repos

## What Changed

`.ai` now provides shared install/uninstall scripts at `~/.ai/lib/` that any downstream repo (like `.shopify-ai`) can use instead of maintaining its own symlink management code.

All agents and skills use **per-file individual symlinks** across all three targets (Claude, OpenCode, Pi). No namespace subdirectories — everything is flat.

## Available at `~/.ai/lib/`

After `.ai/install.sh` runs, these files are symlinked to `~/.ai/lib/`:

| File | Purpose |
|------|---------|
| `install_agents.sh` | Install agent `.md` files as individual symlinks |
| `uninstall_agents.sh` | Remove agent symlinks |
| `install_skills.sh` | Install skill directories (containing `SKILL.md`) as individual symlinks |
| `uninstall_skills.sh` | Remove skill symlinks |
| `agent_helpers.sh` | Library: `install_agents()` / `uninstall_agents()` functions |
| `skill_helpers.sh` | Library: `install_skills()` / `uninstall_skills()` functions |
| `symlink_helpers.sh` | Library: `create_symlink()` / `uninstall_symlink()` / `validate_source_dir()` |
| `logging.sh` | Library: `log_info()` / `log_success()` / `log_warning()` / `log_error()` |
| `paths.sh` | Variables: `CLAUDE_DIR`, `OPENCODE_DIR`, `PI_DIR`, `*_AGENTS_DIR`, `*_SKILLS_DIR` |

## How to Use (Example: `.shopify-ai`)

### install.sh

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$HOME/.ai/lib/logging.sh"

export FORCE_MODE=false
while getopts "f" opt; do
    case $opt in
        f) export FORCE_MODE=true ;;
        *) echo "Usage: install.sh [-f]" >&2; exit 1 ;;
    esac
done

log_info "Starting installation..."

"$HOME/.ai/lib/install_agents.sh" "$SCRIPT_DIR/agents"
"$HOME/.ai/lib/install_skills.sh" "$SCRIPT_DIR/skills"

log_success "✅ Installation complete!"
```

### uninstall.sh

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$HOME/.ai/lib/logging.sh"

echo "Uninstalling..."

"$HOME/.ai/lib/uninstall_agents.sh" "$SCRIPT_DIR/agents"
"$HOME/.ai/lib/uninstall_skills.sh" "$SCRIPT_DIR/skills"

log_success "✅ Uninstall complete!"
```

That's it. The downstream repo's entire `lib/` directory of symlink helpers can be deleted.

## Script Interfaces

### `~/.ai/lib/install_agents.sh <source_dir>`

- Iterates `*.md` files in `<source_dir>`
- Creates individual symlinks in `~/.claude/agents/`, `~/.config/opencode/agents/`, `~/.pi/agent/agents/`
- Uses `create_symlink` (idempotent, respects `FORCE_MODE`)
- Exits with error if `<source_dir>` doesn't exist or no args provided

### `~/.ai/lib/uninstall_agents.sh <source_dir>`

- Iterates entries in each agents dir
- Removes only symlinks whose target points into `<source_dir>`
- Leaves files from other repos untouched

### `~/.ai/lib/install_skills.sh <source_dir>`

- Iterates subdirectories of `<source_dir>` that contain a `SKILL.md`
- Creates individual symlinks in `~/.claude/skills/`, `~/.config/opencode/skills/`, `~/.pi/agent/skills/`
- Directories without `SKILL.md` are skipped

### `~/.ai/lib/uninstall_skills.sh <source_dir>`

- Iterates entries in each skills dir
- Removes only symlinks whose target points into `<source_dir>`
- Leaves files from other repos untouched

## Symlink Layout After Install

```
~/.claude/agents/
    commit-agent.md          → .ai/agents/commit-agent.md
    shopify-review-agent.md  → .shopify-ai/agents/shopify-review-agent.md
    ...

~/.claude/skills/
    commit/                  → .ai/skills/commit/
    create-pr-description/   → .shopify-ai/skills/create-pr-description/
    ...

~/.config/opencode/agents/   (same pattern)
~/.config/opencode/skills/   (same pattern)
~/.pi/agent/agents/          (same pattern)
~/.pi/agent/skills/          (same pattern)
```

No namespace subdirectories. All entries are flat. Agent names and skill names must be unique across repos.

## Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `FORCE_MODE` | `false` | Set to `true` to fix wrong symlinks instead of warning |
| `CLAUDE_DIR` | `~/.claude` | Override Claude config root |
| `OPENCODE_DIR` | `~/.config/opencode` | Override OpenCode config root |
| `PI_DIR` | `~/.pi/agent` | Override Pi config root |
| `CLAUDE_AGENTS_DIR` | `$CLAUDE_DIR/agents` | Override Claude agents dir |
| `CLAUDE_SKILLS_DIR` | `$CLAUDE_DIR/skills` | Override Claude skills dir |
| (same pattern for OPENCODE_* and PI_*) | | |

## What Can Be Deleted from `.shopify-ai`

Once migrated, `.shopify-ai` can remove:
- `lib/symlink_helpers.sh` (replaced by `~/.ai/lib/symlink_helpers.sh`)
- `lib/paths.sh` (replaced by `~/.ai/lib/paths.sh`)
- `lib/logging.sh` (replaced by `~/.ai/lib/logging.sh`)
- Any `install_agents.sh`, `uninstall_agents.sh`, `install_skills.sh`, `uninstall_skills.sh` in its own `lib/`
- All inline `is_correct_symlink` / `create_symlink` / `uninstall_symlink` function definitions
- All `getopts` / `-f` flag parsing in sub-scripts (just `export FORCE_MODE` in the top-level `install.sh`)

## Prerequisite

`.ai` must be installed first (`~/.ai/lib/` must exist). If `.shopify-ai/install.sh` runs before `.ai/install.sh`, the `~/.ai/lib/install_agents.sh` call will fail with "command not found".
