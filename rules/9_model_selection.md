# Model Selection

Practical guidance for choosing a model when spawning agents (e.g. `fleet_spawn`).

| Model | Use for |
|-------|---------|
| **Haiku** | Mechanical/scripted tasks: one-line edits, gitignore changes, simple lookups, short sweeps — anything with no real judgment required |
| **Sonnet** | Implementation, walkthroughs, code review, orchestration, anything requiring judgment but not deep reasoning |
| **GPT-5.5** | General reasoning and implementation. Prefer Anthropic models; use this when a task specifically needs OpenAI strengths (long code generation, certain agentic tasks) or when Anthropic quota is exhausted. Also ideal for adversarial review. |
| **Opus** | Investigation, planning, complex reasoning-heavy tasks where Sonnet would miss things |
| **Fable** | Design work, or investigation where Opus previously failed or got stuck |

## Model strings

Exact strings for the `model` parameter in `fleet_spawn`, `subagent`, and agent frontmatter:

| Tier | String |
|------|--------|
| Haiku | `anthropic/claude-haiku-4-5` |
| Sonnet | `anthropic/claude-sonnet-4` |
| GPT-5.5 | `openai-codex/gpt-5.5` |
| Opus | `anthropic/claude-opus-4` |
| Fable | `anthropic/claude-fable-5` |

## Context files

Pi and Claude Code read from different context files, both built from this repo:

- **Pi** (`~/.pi/agent/AGENTS.md`): `rules/` + `pi/`
- **Claude Code** (`~/.claude/CLAUDE.md`): `rules/` + `claude/`

To add guidance visible to both, add a numbered `.md` to `rules/`. Pi-only goes in `pi/`. Claude-only goes in `claude/`. Rebuild with `bash lib/install_agents_md.sh`.
