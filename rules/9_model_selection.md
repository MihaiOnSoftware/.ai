# Model Selection

Practical guidance for choosing a model when spawning agents (e.g. `fleet_spawn`).

| Model | Use for |
|-------|---------|
| **Haiku** | Mechanical/scripted tasks: one-line edits, gitignore changes, simple lookups, short sweeps — anything with no real judgment required |
| **Sonnet** | Implementation, walkthroughs, code review, orchestration, anything requiring judgment but not deep reasoning |
| **GPT-5.5** | Orchestration, investigative work, adversarial review — ideal when you want a different model family to challenge conclusions |
| **Opus** | Investigation, planning, complex reasoning-heavy tasks where Sonnet would miss things |
| **Fable** | Design work, or investigation where Opus previously failed or got stuck |
