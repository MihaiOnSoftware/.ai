# .ai

Shared configuration for AI coding assistants (Claude Code and OpenCode).

## Installation

The `install.sh` script creates symlinks from your home directory to this repository, allowing AI assistants to access shared scripts, rules, commands, skills, and agents.

### Standard Installation

```bash
./install.sh
```

This creates 8 symlinks:
- `~/.ai/scripts/generic` → `scripts/`
- `~/.ai/rules` → `rules/`
- `~/.claude/commands/generic` → `commands/`
- `~/.claude/skills/generic` → `skills/`
- `~/.claude/agents/generic` → `agents/`
- `~/.config/opencode/commands/generic` → `commands/`
- `~/.config/opencode/skills/generic` → `skills/`
- `~/.config/opencode/agents/generic` → `agents/`

### Force Mode

If symlinks already exist but point to wrong locations:

```bash
./install.sh -f
```

The `-f` flag automatically fixes incorrect symlinks. It will **never** overwrite regular files or directories.

### Advanced: Custom Paths

Override default locations using environment variables:

```bash
AI_SCRIPTS_PATH=~/custom/.ai/scripts/generic \
AI_RULES_PATH=~/custom/.ai/rules \
CLAUDE_COMMANDS_PATH=~/custom/.claude/commands/generic \
CLAUDE_SKILLS_PATH=~/custom/.claude/skills/generic \
CLAUDE_AGENTS_PATH=~/custom/.claude/agents/generic \
OPENCODE_COMMANDS_PATH=~/custom/.config/opencode/commands/generic \
OPENCODE_SKILLS_PATH=~/custom/.config/opencode/skills/generic \
OPENCODE_AGENTS_PATH=~/custom/.config/opencode/agents/generic \
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

You can safely test the installation scripts without affecting your actual configuration by overriding all path variables to point to a test directory:

```bash
# Create test directory structure
mkdir -p /tmp/ai-test/{ai/{scripts,rules},claude/{commands,skills,agents},opencode/{commands,skills,agents}}

# Test install with custom paths
AI_SCRIPTS_PATH=/tmp/ai-test/ai/scripts/generic \
AI_RULES_PATH=/tmp/ai-test/ai/rules \
CLAUDE_COMMANDS_PATH=/tmp/ai-test/claude/commands/generic \
CLAUDE_SKILLS_PATH=/tmp/ai-test/claude/skills/generic \
CLAUDE_AGENTS_PATH=/tmp/ai-test/claude/agents/generic \
OPENCODE_COMMANDS_PATH=/tmp/ai-test/opencode/commands/generic \
OPENCODE_SKILLS_PATH=/tmp/ai-test/opencode/skills/generic \
OPENCODE_AGENTS_PATH=/tmp/ai-test/opencode/agents/generic \
./install.sh

# Test uninstall
AI_SCRIPTS_PATH=/tmp/ai-test/ai/scripts/generic \
AI_RULES_PATH=/tmp/ai-test/ai/rules \
CLAUDE_COMMANDS_PATH=/tmp/ai-test/claude/commands/generic \
CLAUDE_SKILLS_PATH=/tmp/ai-test/claude/skills/generic \
CLAUDE_AGENTS_PATH=/tmp/ai-test/claude/agents/generic \
OPENCODE_COMMANDS_PATH=/tmp/ai-test/opencode/commands/generic \
OPENCODE_SKILLS_PATH=/tmp/ai-test/opencode/skills/generic \
OPENCODE_AGENTS_PATH=/tmp/ai-test/opencode/agents/generic \
./uninstall.sh

# Clean up
rm -rf /tmp/ai-test
```

This allows you to verify the scripts work correctly before running them on your actual configuration.
