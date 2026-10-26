# Example: design doc excerpt

Trimmed from a real design: a redesign of a workflow-status read model after a reviewer pushed back on the shipped-on-branch version. It shows the anchors header, the problem quoting the person who raised it, a verified inventory, a truth table, resolved questions as answer-stating headings, the testing split, scope, and notable decisions. Elided parts are marked `…`.

---

# API-856 redesign: remove `FAILED` from the workflow-status read model

**Date**: 2026-10-23
**Supersedes**: `~/.ai/wip/api-856-design-2026-10-21.md` wherever they conflict (Kysely types, repository, and codegen inventory carry over unchanged).
**Branch**: `MihaiOnSoftware/api-856-enrich-workflow-status-from-installation-workflows` @ `9b7cf8ca` (PR #55441, open)
**Trigger**: Jamal's review on PR #55441 (he owns the writer side, API-378).

## Problem

The current read model derives a GraphQL `FAILED` status (recipes stopped + non-null `error_detail` → `FAILED`), and masks stored `error_detail` whenever any recipe runs. Jamal, on the PR:

> "I think we should avoid exposing FAILED. It puts the responsibility on the UI to infer what state to show by parsing errorDetails … it was really a pain for installations which is why I removed the FAILED status entirely."

The installations model is the precedent (verified in source: `InstallationRepository.markError` sets `errorCode`/`errorMessage` without touching `status`; the installation status enum has no `FAILED`). This redesign adopts it: status and error fields become independent dimensions.

Removing `FAILED` is non-breaking: master's enum is `NOT_ADDED`/`ON` only (verified against `origin/master`).

## What exists today (verified on branch @ 9b7cf8ca)

| Artifact | State |
|---|---|
| `mergeWorkflowStatus` in `WorkflowService.ts` | Pure fn: running → `ON` + null detail (masks stored error); stopped + non-null `error_detail` → `FAILED`; stopped + `CONFIGURING` row → `CONFIGURING`; else `NOT_ADDED`. |
| `WorkflowSummary` | Nested `errorDetail: {code, message} \| null`; the resolver flattens it. |
| Tests | `mergeWorkflowStatus.unit.spec.ts`: 13 cases, mostly FAILED/masking. `WorkflowService.integration.spec.ts`: 7 enrichment cases re-proving the same matrix. |
| Writer side | API-378 not landed; `startRecipes`/`stopRecipes` throw "not implemented". |
| Helper-module precedents | `modules/installations/utils/`: `evaluateConnectionAuthorization.ts`, `classifyConnections.ts`. Pure computation extracted from services, each with its own unit spec. |

## Design

**Status rule**:

```
resolveWorkflowStatus = anyRecipeRunning ? ON
                      : rowStatus === CONFIGURING ? CONFIGURING
                      : NOT_ADDED
```

**Error rule**: `extractWorkflowError(row.errorDetail)` → `{errorCode, errorMessage}`, per field, whenever a row exists. Neither function consults the other.

| Any recipe running? | Row | status | errorCode/errorMessage |
|---|---|---|---|
| yes | absent | `ON` | null/null |
| yes | any, with `error_detail` | `ON` | pass-through (was: masked) |
| no | `CONFIGURING`, with `error_detail` | `CONFIGURING` | pass-through: failed activation |
| no | `ON`, with `error_detail` | `NOT_ADDED` | pass-through |
| … | | | |

### Error extraction: per-field, and zod goes away

Jamal asked whether a valid `message` should survive an invalid `code`. Per field: a writer bug on one field must not destroy the other. With two optional string fields, zod's all-or-nothing default is what caused the question, so plain `typeof` checks replace it. …

### `errorCode` stays `String` (confirmed with Mihai)

The writer has no codes yet; an enum now would be `{UNKNOWN}`-only and would erase every real stored code. Revisit once API-378 fixes the vocabulary. …

## Testing

- **Unit** (`utils/workflowStatus.unit.spec.ts`, replaces the merge spec): the `resolveWorkflowStatus` matrix (~6 cases) and the `extractWorkflowError` matrix (~8 cases).
- **Integration** (`WorkflowService.integration.spec.ts`): trimmed to ~4 wiring proofs through the real stack; the matrix lives in unit.

## Scope

**Non-goals**: writer-side changes (API-378); the `errorCode` enum migration; exposing per-recipe errors.

**Accepted simplifications**: stale stored errors stay visible until the writer clears them, deliberately, per Jamal. `NOT_ADDED` + error fields is representable; no status is invented to prevent it.

## Known risks

- Writer contract: API-378's success paths must clear `error_detail`, or stale errors show next to `ON` indefinitely. Flag to Jamal; not this ticket's code.
- PR #55255 (API-380) touches `WorkflowService.ts`; textual rebase risk.

## Notable decisions

1. `FAILED` removed from the GraphQL enum; status and error fields are independent.
2. Error pass-through is unconditional; the masking rule is deleted.
3. Per-field extraction, zod deleted; the warning on wrong-typed fields stays as the writer-bug signal.
4. `errorCode: String` kept until the writer's vocabulary exists.
5. Helper module `utils/workflowStatus.ts` with two functions; `mergeWorkflowStatus` deleted as a name.

## Open questions (deferred)

1. `errorCode` enum migration timing. Revisit with Jamal when API-378 defines values.
2. Exact `error_detail` key names. Confirm when the writer lands; `extractWorkflowError` is the single update point.

## Suggested slice boundaries

1. Helper module and its unit spec, no consumers yet.
2. `WorkflowService` switch-over, old spec deleted, integration spec trimmed.
3. GraphQL: SDL deletion, docstrings, codegen, resolver and spec updates.

<!-- not yet adversarially reviewed as a complete artifact -->
