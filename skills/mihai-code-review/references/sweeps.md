# Mechanical Sweep Checklists

Run these in Pass 1, before any adversarial hunting. Every item gets a log line: findings or `clean`. Severity defaults are noted per item — they are ceilings for style items (never escalate a guard-clause nit) and floors for test substance (insubstantial tests can escalate to blocker).

## Per-function sweep

For EVERY new or moved function in the diff — including shared helpers and moved code in extraction PRs, not just route handlers / entry points:

| # | Check | Default severity |
|---|---|---|
| F1 | Body wrapped in a conditional (`if (x) { ...whole body... }`) → guard clause would read better. Flag each occurrence separately, even when repetitive across siblings. | `nit:` |
| F2 | A check tests a condition the type signature already rules out → redundant AND untestable (you cannot write a test that reaches it). Double finding. | `nit:`/`minor:` |
| F3 | A branch, `?.`, or `?? default` with no test that fails if it breaks. Ask literally: "what test fails if this breaks?" | `minor:` |
| F3b | A NEW exported function with no dedicated spec at all — incidental coverage through a route's integration specs does not count. This is a missing test. | **blocker** |
| F4 | Multi-clause inline expression that obscures the flow → worth a named function. | `minor:` |
| F5 | One exported function in a shared file accumulating several private helpers only it calls → a concept is trying to emerge; propose its own file (optionally re-exported through the shared file to keep the interface). A shared `common.ts` hosting one function's private empire is the classic case — flag it even when a sibling domain keeps the same shape. | `minor:` |
| F6 | Error message / literal duplicated with a sibling file → worth consolidating? | `minor:` |
| F7 | Positionally adjacent same-type parameters that could swap silently → note it, but cede ("we barely ever use named params so feel free to leave as is"). | `nit:` |

## Per-test-file sweep

For EVERY test file in the diff:

| # | Check | Default severity |
|---|---|---|
| T1 | New test names follow the `should … when …` convention (compare against sibling specs in the same tree). | `nit:` |
| T2 | Vacuous assertions: could this pass even when the behavior breaks? Fixture lacks the data that proves the negative case (flag off + no data = false pass); a lookup silently returning `null` makes `x?.field` falsy-assertions trivially true (soft-delete `getById` without `includeDeleted`). | `minor:` |
| T3 | Can any change to the code this spec belongs to actually fail each test? If not, the test belongs elsewhere (other module, other layer, the mutation side) or should be deleted. | `minor:` |
| T4 | Low-value tests: asserting the code against itself (schema vs literal copy), testing the openapi spec, `toHaveBeenCalled` echoing the expected result, testing another unit's internals. | `nit:` |
| T5 | Assertion quality: richer assertion over true/false or `toHaveLength`; expected results as literals, not references to the input ("if the mutation result shape changes the rest result shouldn't necessarily change with it"). | `nit:` |
| T6 | Edge values for id/number coercion code: zero, negatives, overflow (`2147483648`), leading-zero strings (`"05"`). | `minor:` |
| T7 | Extraction/refactor PRs: new unit specs supersede existing integration spec cases → itemize them with file/line links and recommend deletion (deletion is the default; keeping wiring coverage is the author's call). Also: callers' integration specs should slim down. | `minor:` |
| T8 | Test substance: the test file exists but asserts nothing substantive about what it builds (checks existence but none of the wiring, config values, or payload fields). This one is a **blocker** — it counts as a missing test. | **blocker** |
| T9 | Missing coverage vs siblings: comparable code elsewhere has a test this change lacks (e.g. other flag-gated columns have E2E coverage). Call out the gap without demanding it. | `minor:` |

## Comment sweep

For EVERY comment added or moved in the diff:

| # | Check | Default severity |
|---|---|---|
| C1 | Comment explains what a block does → "a function with a good name could replace the comment" / "a function trying to manifest". | `nit:` |
| C2 | Comment repeats what the code says → remove. | `nit:` |
| C3 | Comment references module names, ticket numbers, or other code → "going to go stale very fast". | `nit:` |
| C4 | Comment documents behavior → "This should be enforced via tests not in a comment". | `minor:` |
| C5 | Comment is author's-context material → better on the commit message / PR description. | `nit:` |
| C6 | Inverse check: a non-obvious intentional value (`null` slot, deliberate omission) with NO comment where a sibling has one → ask for it. | `nit:` |
| C7 | Comment contradicts the code it documents (doc says X, code does Y) → flag; may reveal a real bug underneath. | `minor:`+ |

## Leftovers / metadata sweep

Once per PR:

| # | Check | Default severity |
|---|---|---|
| L1 | Changelog honesty: ANY behaviour change — however small, however beneficial — contradicting "no behaviour change"; availability field accuracy ("technically not GA"). | `minor:` (expected fix) |
| L2 | Orphaned leftovers from the change itself: config fields nothing reads, deps left in the old package.json after their consumer moved, dead mock data, stale TODOs referencing the current ticket. | `minor:` |
| L3 | Unrelated files carried in the PR (generated files from another team's surface) → revert. | **`major:`** |
| L4 | Migration filenames mention everything the migration does; migration safety rules (`docs/rules/database-migration-standards.md`). | `minor:`/`question:` |
| L5 | Ticket satisfied: does the PR cover what the ticket names (e.g. native UI called out but absent)? If deferred, is there a ticket? | `question:` |
| L6 | Names match what the thing is (error names); module-level constants follow the codebase case convention (SCREAMING_SNAKE_CASE) — check every new `const` at module scope, including regexes. | `nit:` |

## Precedent-diff checklist (Pass 2)

For each piece of new infrastructure or UI, after finding the nearest sibling implementation:

- File/module location matches the sibling's layout
- Config shape and placement (domain config lib vs service config; duplication with existing config classes)
- Types: alias the real package type (`SqsMessageProducer<Payload>`) over hand-rolled interfaces
- Env vars and envelope fields the pattern reads (`DD_SERVICE_NAME`)
- Logging parity: success/info logs the sibling emits; warn-vs-info semantics for disabled paths
- Test utilities the sibling's tests reuse (test-kit loggers, factories)
- **UI components: props/pattern alignment with sibling components** (the other cards/rows/pages that do the same thing — spacing props, wrapper elements, analytics implications of reused components, derivation living in the component that owns the data)
- Import paths via the established aliases, not relative reaches across packages

Link every divergence to the precedent's exact file/line. When the codebase is inconsistent, say so and pick the closest/most common pattern without blocking.
