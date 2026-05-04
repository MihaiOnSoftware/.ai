# .ai

Shared configuration for AI coding assistants (Claude Code, OpenCode, and pi).

## Installation

The `install.sh` script creates symlinks from your home directory to this repository, allowing AI assistants to access shared scripts, rules, skills, and agents.

### Standard Installation

```bash
./install.sh
```

This creates symlinks:

**Shared library and project files**
- `~/.ai/lib/<helper>.sh` → `lib/<helper>.sh` (per file: `logging.sh`, `symlink_helpers.sh`, `paths.sh`, `agent_helpers.sh`, `install_agents.sh`, `uninstall_agents.sh`, `skill_helpers.sh`, `install_skills.sh`, `uninstall_skills.sh`)
- `~/.ai/scripts/generic` → `scripts/`
- `~/.ai/rules` → `rules/`

**Per-tool skills and agents** (flat, one symlink per skill/agent)
- `~/.claude/skills/<skill-name>` → `skills/<skill-name>/`
- `~/.claude/agents/<agent>.md` → `agents/<agent>.md`
- `~/.config/opencode/skills/<skill-name>` → `skills/<skill-name>/`
- `~/.config/opencode/agents/<agent>.md` → `agents/<agent>.md`
- `~/.pi/agent/skills/<skill-name>` → `skills/<skill-name>/`
- `~/.pi/agent/agents/<agent>.md` → `agents/<agent>.md`

Skills and agents are symlinked individually (rather than via a single namespace directory) because Claude Code only discovers skills one level deep, and the flat layout keeps all three targets consistent.

### Shared Libraries Only

If you only want the shared install/uninstall helpers (so a downstream repo like `.shopify-ai` can call `~/.ai/lib/install_skills.sh` etc.) without symlinking this repo's own skills, agents, scripts, or rules:

```bash
./lib/install_lib.sh
```

This only creates the `~/.ai/lib/<helper>.sh` symlinks. See [`wip/shared-install-helpers-summary.md`](wip/shared-install-helpers-summary.md) for how downstream repos use them.

### Force Mode

If symlinks already exist but point to wrong locations:

```bash
./install.sh -f
```

The `-f` flag automatically fixes incorrect symlinks. It will **never** overwrite regular files or directories.

### Advanced: Custom Paths

The installer honors the upstream tools' own config-root env vars:

| Variable | Default | Origin |
|---|---|---|
| `CLAUDE_CONFIG_DIR` | `~/.claude` | Claude Code |
| `OPENCODE_CONFIG_DIR` | `~/.config/opencode` | OpenCode |
| `PI_CODING_AGENT_DIR` | `~/.pi/agent` | pi |

If you've already set any of those for the real tools, our installer follows along automatically. To redirect everything to a custom tree:

```bash
CLAUDE_CONFIG_DIR=~/custom/.claude \
OPENCODE_CONFIG_DIR=~/custom/.config/opencode \
PI_CODING_AGENT_DIR=~/custom/.pi/agent \
./install.sh
```

Individual subdirectories can also be overridden directly:

```bash
AI_LIB_PATH=~/custom/.ai/lib \
AI_SCRIPTS_PATH=~/custom/.ai/scripts/generic \
AI_RULES_PATH=~/custom/.ai/rules \
CLAUDE_SKILLS_DIR=~/custom/.claude/skills \
CLAUDE_AGENTS_DIR=~/custom/.claude/agents \
OPENCODE_SKILLS_DIR=~/custom/.config/opencode/skills \
OPENCODE_AGENTS_DIR=~/custom/.config/opencode/agents \
PI_SKILLS_DIR=~/custom/.pi/agent/skills \
PI_AGENTS_DIR=~/custom/.pi/agent/agents \
./install.sh
```

This is useful for:
- Testing in isolated environments
- Custom installation locations
- CI/CD pipelines

### Safety Features

The installer:
- ✅ Skips existing correct symlinks
- ✅ Creates missing parent directories automatically
- ✅ Validates source directories exist before installing
- ⚠️ Warns on wrong symlinks (suggests `-f`)
- ❌ Errors on regular files/directories (never overwrites)

## Uninstallation

To remove the symlinks created by the installation script, use the `uninstall.sh` script:

```bash
./uninstall.sh
```

This script safely removes only the symlinks pointing to this repository. It uses the same environment variables as the installation script to locate the symlinks.

## Testing

You can safely test the installation scripts without affecting your actual configuration by pointing the three config-root env vars at a test directory:

```bash
# Test install with custom paths
AI_LIB_PATH=/tmp/ai-test/ai/lib \
AI_SCRIPTS_PATH=/tmp/ai-test/ai/scripts/generic \
AI_RULES_PATH=/tmp/ai-test/ai/rules \
CLAUDE_CONFIG_DIR=/tmp/ai-test/claude \
OPENCODE_CONFIG_DIR=/tmp/ai-test/opencode \
PI_CODING_AGENT_DIR=/tmp/ai-test/pi/agent \
./install.sh

# Test uninstall (use the same overrides)
AI_LIB_PATH=/tmp/ai-test/ai/lib \
AI_SCRIPTS_PATH=/tmp/ai-test/ai/scripts/generic \
AI_RULES_PATH=/tmp/ai-test/ai/rules \
CLAUDE_CONFIG_DIR=/tmp/ai-test/claude \
OPENCODE_CONFIG_DIR=/tmp/ai-test/opencode \
PI_CODING_AGENT_DIR=/tmp/ai-test/pi/agent \
./uninstall.sh

# Clean up
rm -rf /tmp/ai-test
```

The installer creates any missing parent directories automatically, so no `mkdir` is needed beforehand.
