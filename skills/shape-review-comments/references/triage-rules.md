# Triage Rules

## Drop unconditionally

These never make it into a posted comment, regardless of how interesting the underlying observation is.

**Unrealistic inputs**
- Property names that are JS prototype keys (`__proto__`, `toString`, `constructor`) — nobody names an API property that
- Property names that are path metacharacters (`"[]"`, names with dots) — same reason
- Circular schema objects — doesn't happen in normal OpenAPI construction
- Non-string external IDs when the schema already says `type: "string"` and the middleware validates — the function's contract is protected upstream

**Defensive programming against our own code**
- Guards that protect against malformed responses from our own handlers (`{ errors: [null] }`)
- Type checks on values we control
- The general principle: "we shouldn't add extra checks 'just in case' for our own code — or else we'll end up with a crazy amount of pointless error handling polluting everything"

**Compiler artifacts**
- `?.` that can't actually miss but is there to satisfy TS narrowing
- Type casts that exist because of TS limitations, not logic errors
- Same reasoning: if it's "for the compiler", it's not worth a comment

**Already answered elsewhere**
- Questions whose answer is in the PR description
- Things the author and reviewer already discussed and resolved in DMs or prior comments
- Pre-existing code the PR only moves or touches incidentally — note it at most, don't block on it

**Pure style where the codebase has no standard**
- Import order, formatting — tooling owns those
- Naming patterns where the codebase is inconsistent and there's no clear winner

**Repetition of a finding already on the PR**
- If the same issue was already raised in a prior review round, don't re-raise it

---

## Drop or downgrade to nit

These survive only as nits, and only if the fix is genuinely easy and the finding is real (not just theoretical):

**Theoretical-only issues**
If something can only break under conditions that won't realistically occur in this codebase, prefix with "in theory" and mark as `nit:`. Add "Unlikely someone would use that though, up to you how to handle it." if the path is especially contrived.

**Minor duplication**
Two places build the same string literal — worth flagging only if a helper would be meaningfully cleaner, and even then it's a nit with an explicit "might not be worth it though".

**Doc comments that partially repeat each other**
Only worth a nit if the duplication is significant and both comments are in the same file. Cross-file doc duplication: drop.

---

## Keep as minor or above

**Untested branches**
An isolated uncovered branch (`?.`, `?? default`, ternary arm) with no test that fails when it breaks. Label `minor:`. Anchor on the production line.

Distinct from *meaningful new behavior with no substantive coverage* — a new exported function or feature where no test exercises it at all. That can block. Apply judgment: a single guard clause is `minor:`, an entire untested code path is potentially blocking.

**Spec/runtime disagreement**
The validator or doc says X, the runtime does Y. Label `minor:` unless it's a hard invariant mismatch, then `major:`.

**Missing tests for meaningful new behavior**
A specific behavior has no test that would fail if it broke. Label `minor:` for individual branches; label `major:` if an entire new export has no substantive test at all.

**Naming disagreement within the same file**
When a function name and its return type say different things (e.g. `getPaths` returns `Pair[]`), or when two closely related concepts share a name that creates confusion. Label `nit:`.

**Precedent divergence**
When the PR introduces a pattern and there's a clear sibling in the codebase doing it differently with no apparent reason. Label `minor:` if it creates inconsistency that will matter, `nit:` if cosmetic. Always link the exact sibling file:line.

**Correctness holes that would affect callers**
Logic that can produce wrong output under reachable inputs. Label based on severity — `minor:` if edge-case or pre-existing, `major:` if it affects the main path.

---

## Severity labels

| Label | Use for | Blocks? |
|---|---|---|
| `nit:` | Style, test naming, assertion quality, cosmetic improvements. Explicitly ignorable. | Never |
| `minor:` | Worth doing — untested branches, weak assertions, naming, structural cleanups. Author's call. | No |
| `major:` | Must fix — logic error, unrelated change carried in the PR, new export with zero substantive test coverage. | Yes |
| `question:` | Genuine inquiry — behavior that might be deliberate, design choice worth confirming. | No |
| `discussion:` | Out-of-scope design exploration. Expects an answer, not a change. | No |

**Missing tests are `minor:`, not blockers** — unless the tested behavior is a core invariant with no other safety net.

---

## One finding, one comment

Don't combine multiple unrelated findings into one comment. If two findings are on adjacent lines and tightly coupled, one comment is fine. Otherwise separate them.

The exception: if two findings are the same class of issue on different lines of the same function, a single comment noting both lines is cleaner than two near-identical comments.
