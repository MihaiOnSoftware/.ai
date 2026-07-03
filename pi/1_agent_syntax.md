# Pi Agent Model Strings

When spawning agents, use `provider/model` format. Map from tier to model string:

| Tier | Model string |
|------|-------------|
| Haiku | `anthropic/claude-haiku-4-5` |
| Sonnet | `anthropic/claude-sonnet-4-6` |
| GPT-5.5 | `openai-codex/gpt-5.5` |
| Opus | `anthropic/claude-opus-4-8` |
| Fable | `anthropic/claude-fable-5` |

In agent frontmatter (`agents/*.md`):
```yaml
model: anthropic/claude-sonnet-4-6
```

In `fleet_spawn` or the `subagent` tool's `model` parameter:
```
anthropic/claude-sonnet-4-6
```
