# Design: Fix pi-subagents `subagent` double-registration in fanout children

## Problem

When a pi agent definition lists `subagent` in its `tools:` allowlist **and** is dispatched
as a child via `subagent()`, the child pi process crashes on startup:

```
Error: Failed to load extension ".../pi-subagents/src/extension/index.ts":
Tool "subagent" conflicts with .../pi-subagents/src/extension/fanout-child.ts
```

This blocks `adversarial-review-loop-agent` from spawning its own fresh-context
adversarial subagents while it itself runs as a child. As a stop-gap, `subagent`
was removed from that agent's `tools:` list (`agents/adversarial-review-loop-agent.md`),
which disables the loop's core mechanism (per-iteration fresh-context reviewers).

**Goal:** let the agent get a working `subagent` tool as a fanout child, without the conflict,
**without modifying the `pi-subagents` npm package** (package install — only agent definitions
and pi project config are editable).

## Root cause

Confirmed by reading source (paths are under `~/.pi/agent/npm/node_modules/`):

1. **`runs/shared/pi-args.ts`** (`buildPiArgs`):
   - `fanoutAuthorized = declaredBuiltinTools.includes("subagent")` — true iff `subagent`
     is in the agent's `tools:` list.
   - When `fanoutAuthorized`, it (a) sets env `PI_SUBAGENT_FANOUT_CHILD=1` and the nested-route
     env vars, and (b) **always** adds `fanout-child.ts` to `runtimeExtensions`, emitted as
     `--extension <fanout-child.ts>`.
   - The crucial branch:
     ```ts
     if (input.extensions !== undefined) {
         args.push("--no-extensions");           // suppress package auto-discovery
         // ...emit runtimeExtensions + toolExtensionPaths + input.extensions as -e
     } else {
         // ...emit only runtimeExtensions + toolExtensionPaths as -e
         //    package extensions STILL auto-load
     }
     ```

2. **`extension/index.ts`** (the pi-subagents package extension, auto-loaded unless
   `--no-extensions`): in child mode it calls `registerFanoutChildSubagentExtension(pi)`
   when `PI_SUBAGENT_FANOUT_CHILD=1` — registering the `subagent` tool.

3. **`extension/fanout-child.ts`** (the `-e` runtime extension added by pi-args): its default
   export **also** registers the `subagent` tool when `PI_SUBAGENT_FANOUT_CHILD=1`.

4. **`@earendil-works/pi-coding-agent` `core/resource-loader.ts` → `detectExtensionConflicts`**:
   compares tools across loaded extensions; two *different* extension paths registering the same
   tool name → `Tool "subagent" conflicts with <other path>`.

The de-dup guard inside `registerFanoutChildSubagentExtension` is a `WeakSet<ExtensionAPI>` keyed
on the `pi` instance. `index.ts` and the `-e fanout-child.ts` are loaded as **separate
extensions with separate `pi` instances**, so the guard does not catch this — and the loader's
conflict detector fires regardless.

**Net:** the conflict occurs **only** when `fanoutAuthorized` is true **and** `agent.extensions`
is `undefined` (the default), because that is the only path where both `index.ts` (auto-loaded)
and `fanout-child.ts` (`-e`) register `subagent`. When `agent.extensions` is defined,
`--no-extensions` suppresses `index.ts`, leaving `fanout-child.ts` as the sole registrant — no
conflict.

## Why the obvious alternatives don't work

- **Drop `subagent`, list `fanout-child.ts` as a `tools:` path instead.** A `.ts` path in `tools:`
  is treated as a tool-extension path, so `declaredBuiltinTools.includes("subagent")` is false →
  `fanoutAuthorized=false` → `PI_SUBAGENT_FANOUT_CHILD=0` and the nested-route env vars are blanked.
  Both `index.ts` and `fanout-child.ts` then early-return (their guard requires
  `PI_SUBAGENT_FANOUT_CHILD=1`), so **no `subagent` tool registers at all**, and the nested fanout
  plumbing is unwired. Dead end.
- **Keep `subagent` and keep `extensions` undefined.** That is exactly the broken case.
- **Env-var override.** Agent definitions / project config can't inject the child's process env to
  break the tie.

`fanoutAuthorized=true` (i.e. `subagent` in `tools:`) is *required* for both the tool and its
nested-route wiring. The only lever left that suppresses `index.ts` auto-load is `--no-extensions`,
which `buildPiArgs` triggers by defining `agent.extensions`.

## Chosen fix

Define `extensions:` in the agent frontmatter so `buildPiArgs` takes the `--no-extensions` branch,
and re-add the one package extension the agent actually depends on (`pi-intercom`).

Edit `agents/adversarial-review-loop-agent.md` frontmatter:

```yaml
tools: read, grep, find, ls, bash, edit, write, intercom, subagent
extensions: ~/.pi/agent/npm/node_modules/pi-intercom
```

(Restores `subagent`; adds the `extensions:` line.)

### Why this works (mechanics, all verified against source)

1. `agent.extensions` is now defined → `buildPiArgs` emits `--no-extensions` → the pi-subagents
   package `index.ts` is **not** auto-discovered/loaded in the child.
2. `fanoutAuthorized` stays true (`subagent` still in `tools:`) → `fanout-child.ts` is still added
   to `runtimeExtensions` and emitted as `-e`, and `PI_SUBAGENT_FANOUT_CHILD=1` + nested-route env
   vars are set. `fanout-child.ts` registers `subagent` **exactly once** → no conflict.
3. `--no-extensions` only disables extension *discovery*; explicit `-e` paths still load
   (`resource-loader.ts` reload: `extensionPaths = noExtensions ? cliEnabledExtensions : merge(...)`).
   The always-added `subagent-prompt-runtime.ts` and `fanout-child.ts` therefore still load.
4. **Skills are unaffected by `--no-extensions`** — skill paths are resolved from package discovery
   independently of `noExtensions` in the same reload routine. The agent's `adversarial-review` /
   `adversarial-review-loop` skills (present under `~/.pi/agent/skills/` and the project) keep loading.
5. **`pi-intercom` is re-added and loads:** pi resolves `-e` paths via
   `package-manager.ts → parseSource`. `~/.pi/agent/npm/node_modules/pi-intercom` is classified
   `local` (no `npm:`/`git:`/`http:` prefix), then `resolvePathFromBase → resolvePath(..., {homeDir})`
   expands the leading `~/` (`expandTilde ?? true` in `normalizePath`) to an absolute path. The
   directory exists; `collectPackageResources` reads its `pi.extensions: ["./index.ts"]` and loads
   it → `intercom` + `contact_supervisor` tools register.
6. **The intercom bridge stays active.** `intercom-bridge.ts → extensionSandboxAllowsIntercom`
   inspects the raw `agent.extensions` entries; `~/.pi/agent/npm/node_modules/pi-intercom`
   matches `endsWith("/pi-intercom")`, so `applyIntercomBridgeToAgent` still injects
   `intercom` + `contact_supervisor` into the tools allowlist and prepends the bridge instructions.
   This is the *intended* mechanism for sandboxed (extensions-defined) agents to opt into intercom.
7. **`--tools` allowlist:** `subagent`, `intercom`, `contact_supervisor` are all present in the
   effective tools list (the bridge adds `intercom`/`contact_supervisor`), so the registered tools
   are not filtered out. (`--tools` gates builtin + extension + custom tools.)
8. **Depth:** `DEFAULT_SUBAGENT_MAX_DEPTH = 2`. The loop agent dispatched by the top-level
   orchestrator runs at `PI_SUBAGENT_DEPTH=1`; `checkSubagentDepth` → `1 >= 2` is false, so it can
   spawn nested reviewers at depth 2. The primary use case is not depth-blocked.

### What is intentionally lost (and why it's fine)

`--no-extensions` also stops the child from auto-loading `pi-mcp-adapter`, `pi-web-access`,
`@latentminds/pi-quotas`, `@juicesharp/rpiv-ask-user-question`. The agent lists none of their tools,
so under the previous (working) setup those extensions loaded but were filtered out by the `--tools`
allowlist anyway. No functional change for this agent. The pi-subagents `index.ts` itself is only a
fanout-child registrant in child mode, which `fanout-child.ts` fully replaces — nothing lost.

## Implementation slices

This is a one-file, two-line change plus a verification pass.

1. **Apply frontmatter change** to `agents/adversarial-review-loop-agent.md`:
   restore `subagent` in `tools:`, add `extensions: ~/.pi/agent/npm/node_modules/pi-intercom`.
2. **Verify launch** — dispatch the loop agent as a child and confirm: no extension-load error;
   `subagent`, `intercom`, `contact_supervisor` are all available; an in-loop fresh-context
   reviewer dispatch succeeds end-to-end.

## Open questions / risks to confirm during verification

- **Path assumption.** The fix assumes `pi-intercom` is installed at *user* scope under
  `~/.pi/agent/npm/node_modules`. This matches `~/.pi/agent/settings.json` (`npm:pi-intercom`) and
  the verified on-disk location. If a future install moves it to project scope or a different
  agent dir, the path must be updated. (`npm:pi-intercom` was rejected: as a `-e` source it resolves
  against the *temporary* scope install path, which may be absent → triggers a network install /
  offline skip. The local tilde path is more robust and self-contained.)
- **Deeper orchestration chains.** If the loop agent is ever itself dispatched at depth ≥ 2, its
  nested reviewers (depth ≥ 3) would be depth-blocked under the default `maxSubagentDepth=2`.
  Current usage (orchestrator → loop agent → reviewer) is fine. If deeper nesting is needed, set
  `maxSubagentDepth` in `~/.pi/agent/extensions/subagent/config.json` or the agent frontmatter.
- **Other agents.** Any other local agent that wants `subagent` while running as a child will hit
  the same bug and needs the same `extensions:` treatment. Consider documenting this pattern.

## Recommended upstream fix (report to pi-subagents; not required for our workaround)

The bug is in `runs/shared/pi-args.ts`: `fanout-child.ts` is added to `runtimeExtensions`
unconditionally, even when the package `index.ts` will also auto-load and register the fanout child.
Gate it on whether discovery is suppressed:

```ts
const runtimeExtensions = (fanoutAuthorized && input.extensions !== undefined)
    ? [PROMPT_RUNTIME_EXTENSION_PATH, FANOUT_CHILD_EXTENSION_PATH]
    : [PROMPT_RUNTIME_EXTENSION_PATH];
```

Rationale: when `extensions === undefined`, package discovery loads `index.ts`, which already
registers the fanout child — so adding `fanout-child.ts` as `-e` is redundant and causes the
conflict. When `extensions !== undefined`, `--no-extensions` suppresses `index.ts`, so
`fanout-child.ts` must be added explicitly. This fixes both paths.

Alternative upstream fix: make the de-dup guard process-global (e.g. a `globalThis` flag) instead of
per-`ExtensionAPI` `WeakSet`, so the second registrant no-ops and contributes zero tools. The
`runtimeExtensions` conditional above is cleaner and more targeted.

## Notable decisions

- Workaround lives entirely in the editable agent definition; the npm package is untouched
  (per constraint).
- Re-adding `pi-intercom` via its sandbox-recognized path leverages the bridge's existing
  `extensionSandboxAllowsIntercom` design — this is the supported way to keep intercom under an
  extension sandbox, not a hack.
- `~/`-prefixed local path chosen over an absolute path (portable across users on the standard
  `~/.pi/agent/npm` layout) and over `npm:pi-intercom` (avoids temporary-scope resolution / network).
```
