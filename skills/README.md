# Skills Directory

This directory contains skills that can be loaded on-demand by Claude Code, OpenCode, and pi agents.

## Structure

Each skill must be in its own subdirectory with a `SKILL.md` file:

```
skills/
  skill-name/
    SKILL.md
    references/   (optional)
    examples/     (optional)
    scripts/      (optional)
```

## Symlinks

Each skill is symlinked individually (per-skill, flat layout) into all three target tools:

- `~/.claude/skills/<skill-name>` → `skills/<skill-name>/`
- `~/.config/opencode/skills/<skill-name>` → `skills/<skill-name>/`
- `~/.pi/agent/skills/<skill-name>` → `skills/<skill-name>/`

The flat layout is required because Claude Code only discovers skills one level deep (`<skills-dir>/<skill-name>/SKILL.md`), and keeping all three targets identical avoids per-tool special cases.

## Adding a New Skill

1. Create directory: `mkdir skills/my-skill`
2. Create `skills/my-skill/SKILL.md` with frontmatter:
   ```yaml
   ---
   name: my-skill
   description: Brief description of what this skill does
   license: MIT
   metadata:
     category: <category>
   ---

   Skill instructions here...
   ```
3. Re-run `./install.sh` to symlink the new skill into the three target tools.
