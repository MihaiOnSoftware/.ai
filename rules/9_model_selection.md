# Model Selection

Practical guidance for choosing a model when spawning agents (e.g. `fleet_spawn`).

| Model | Use for |
|-------|---------|
| **Haiku** | Mechanical/scripted tasks: one-line edits, gitignore changes, simple lookups, short sweeps — anything with no real judgment required |
| **Sonnet** | Implementation, walkthroughs, code review, orchestration, anything requiring judgment but not deep reasoning |
| **GPT-6** | Orchestration, investigative work, adversarial review — ideal when you want a different model family to challenge conclusions |
| **Opus** | Investigation, planning, complex reasoning-heavy tasks where Sonnet would miss things |
| **Fable** | Design work, or investigation where Opus previously failed or got stuck |

## Pi Agent Model Strings

When spawning agents, use `provider/model` format. Map from tier to model string:

| Tier | Model string |
|------|--------------|
| Haiku | `anthropic/claude-haiku-4-5` |
| Sonnet | `anthropic/claude-sonnet-4-6` |
| GPT-6 | `openai-codex/gpt-6-sol` |
| Opus | `anthropic/claude-opus-4-8` |
| Fable | `anthropic/claude-fable-5` |
