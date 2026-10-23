# Pi Agent Model Strings

When spawning agents, use `provider/model` format. Map from tier to model string:

| Tier | Model string |
|------|-------------|
| Haiku | `anthropic/claude-haiku-5-5` |
| Sonnet | `anthropic/claude-sonnet-5-5` |
| GPT-6.1 | `openai-codex/gpt-6.1-sol` |
| Opus | `anthropic/claude-opus-5-5` |
| Fable | `anthropic/claude-fable-5-1` |

In agent frontmatter (`agents/*.md`):
```yaml
model: anthropic/claude-sonnet-5-5
```

In `fleet_spawn` or the `subagent` tool's `model` parameter:
```
anthropic/claude-sonnet-5-5
```
