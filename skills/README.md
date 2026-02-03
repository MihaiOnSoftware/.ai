# Skills Directory

This directory contains OpenCode/Claude Code skills that can be loaded on-demand by agents.

## Structure

Each skill must be in its own subdirectory with a `SKILL.md` file:

```
skills/
  skill-name/
    SKILL.md
```

## Symlinks

This directory is symlinked to both OpenCode and Claude Code configs:

- `~/.config/opencode/skills/generic` → this directory
- `~/.claude/skills/generic` → this directory

**Note**: Unlike commands, skills do NOT use the namespace prefix in their names. Skills are referenced by their base name (e.g., `load-rules`) regardless of where they're symlinked. The `generic` directory is just for organization/discovery.

## Skills vs Commands

**Commands** (in `commands/`):
- Flat `.md` files
- Invoked directly: `/command-name`
- Symlinked to `~/.config/opencode/commands/generic`

**Skills** (in `skills/`):
- Each skill in `skill-name/SKILL.md` structure
- Loaded on-demand via skill tool
- Agent sees available skills and chooses when to load

## Current Skills

- `load-rules` - Load all user rules from ~/.ai/rules/ directory

## Adding a New Skill

1. Create directory: `mkdir skills/my-skill`
2. Create `skills/my-skill/SKILL.md` with required frontmatter:
   ```yaml
   ---
   name: my-skill
   description: Brief description of what this skill does
   license: MIT
   compatibility: opencode
   ---
   
   Skill instructions here...
   ```
3. Skill is automatically available through the symlinks
