# Example: design doc excerpt

Excerpt from `design/admin-api-types.md` in `shopify-playground/flow-js-playground`. Shows the structure: problem → what exists today (with verdicts) → why we can't just reuse the obvious thing → architecture diagram → accepted simplification → SDK side.

The full doc is ~270 lines. This excerpt shows the load-bearing sections.

---

# Admin API types for user scripts

Design for providing TypeScript types covering the Shopify Admin GraphQL API
(inputs and outputs) to devs and LLMs writing/maintaining user scripts in
flow-js-playground.

## Problem

A user script in this playground needs to call the Shopify Admin GraphQL API
through a `step('adminQuery', ...)` / `step('adminMutation', ...)` library
function (interface owned elsewhere). For the script to be typesafe and for
LLMs to maintain it over a long lifespan, we need typed `Variables` and typed
response shapes — both pulled from the Admin API's GraphQL schema.

## What Flow already has

| Artifact | Path | Notes |
|---|---|---|
| Versioned Admin API schema (Flow-internal format) | `schema/graphql/<v>.json` | Heavily processed; **not** suitable as an SDK source — see below |
| Raw Admin API SDL (used by Cusco for typed Ruby calls) | `lib/flow_core/infrastructure/admin/admin_api/schema.graphql` | 7.4MB SDL, not version-pinned |
| Static per-version patches | `schema/flow/<v>/{fields,objects}/*.json` | Back-compat for renamed/replaced fields |
| Mutation/query denylist | `lib/flow_runtime/graph_q_l/schema/ingestion/allowlist.rb` (`ADMIN_API_DENYLIST`) | ~55 mutations Flow blocks from workflows |
| Frontend codegen pattern | `app/ui/tooling/refreshGraphql.ts` | `graphql-typescript-definitions` reading per-project `graphql.config.ts` |

### Why Flow's processed `schema/graphql/<v>.json` is not usable

Flow's ingest pipeline applies transforms that are lossy from an Admin API
client's perspective:

- `transform_paginated_types` strips all `*Connection`/`*Edge` types and
  rewrites paginated fields to plain lists. The real Admin API still returns
  connections — a script generated against Flow's schema would write invalid
  queries.
- `prune_unreachable_from` keeps only types reachable from a 20-name root
  set — drops ~2000 types that a user script may legitimately want.
- `prune_denylisted_fields` and `prune_denylisted_interfaces` remove
  workflow-specific fields.
- `add_auxiliary_types` adds Flow-only types like `HttpResponse` that aren't
  part of the real API.

These transforms are correct for Flow's workflow engine. They're wrong for an
SDK whose consumers query the real Admin API.

### Why we don't need dynamic per-shop types

The Admin API GraphQL **schema** is shop-agnostic at the wire level. What
varies per shop is **data**, not schema:

- Metafield/metaobject definitions vary per shop, but they're exposed through
  the generic `metafield(namespace, key): Metafield` field. The value is
  always typed `Metafield.value: String!` — regardless of whether the
  underlying definition is boolean, number, reference, etc.
- OAuth scope gating (`requiredAccess` on 602 fields) is **app-scope** gating,
  not shop gating. Same schema for everyone.

**Accepted simplification**: a script reading `metafield.value` for a
custom-typed metafield gets `string`, not the actual type. Parsing the value
is the script's concern. A typed-value helper is out of scope for v1.

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│ Flow (Rails app)                                             │
│                                                              │
│  rake schema:export_sdl                                      │
│   ├─ Raw introspection (existing — same as schema:ingest)    │
│   ├─ Ingestion::Allowlist (existing — denied mutations out)  │
│   └─ Introspection JSON → SDL (new converter)                │
│         │                                                    │
│         ▼                                                    │
│  schema/sdk-exports/<api_version>.graphql  (committed)       │
│                                                              │
│  GET /admin-graphql-schema/latest.graphql  →  serves file    │
└──────────────────────────────────────────────────────────────┘
                            │
                            ▼ (at SDK release time, NOT user runtime)
┌──────────────────────────────────────────────────────────────┐
│ SDK build pipeline                                           │
│  curl …/admin-graphql-schema/latest.graphql                  │
│        > package/schema/admin.graphql                        │
└──────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌──────────────────────────────────────────────────────────────┐
│ User project                                                 │
│  src/queries/getProduct.graphql       (hand-written)         │
│              │                                               │
│              ▼ pnpm refresh-graphql                          │
│  src/queries/getProduct.graphql.d.ts  (auto-generated)       │
└──────────────────────────────────────────────────────────────┘
```

## Flow side — Reuse / Do NOT reuse / New

### Reuse

- `FlowRuntime::GraphQL::Shopify::Flow#request(GraphqlSchemaParser.query)` — introspection.
- `FlowRuntime::GraphQL::Schema::Ingestion::Allowlist#generate` — verbatim Flow denylist.

### Do NOT reuse

- `Patches.merge` (Flow legacy back-compat)
- `transform_paginated_types`
- `prune_unreachable_from`
- `prune_denylisted_fields` / `prune_denylisted_interfaces`
- `add_auxiliary_types`

### New

- **`rake schema:export_sdl`** in `lib/tasks/schema.rake`. …
- **Route** `GET /admin-graphql-schema/latest.graphql`. …

### Auth

**Public for now.** The output is the Admin API schema minus already-curated
denied ops — no shop data, no secrets. Flagged as a follow-up before shipping
to production: at minimum require an authenticated Shopify session or
service-app token. This becomes urgent once the SDK leaves internal use.

## Open questions / follow-ups

1. Whether to bundle the SDL in the SDK package or fetch at install time. Proposed: bundle (deterministic, offline). Alternative: fetch (smaller package). Need user call.
2. Where the build-time `curl` lives — `prepublishOnly` script or a separate CI step. Proposed: `prepublishOnly`. Need user call.
3. Metafield-typed-value helper deferred to v2.

---

## What this excerpt demonstrates

- **Problem statement** in one paragraph.
- **"What exists today"** is an inventory table with `Notes` doubling as the verdict column.
- **Why we can't just reuse the obvious thing** gets a dedicated sub-section per artifact. Concrete reasons, not "doesn't fit."
- **Architecture diagram** crosses system boundaries (Flow Rails app / SDK build / user project), with the labels on the arrows telling you *what* crosses and *when*.
- **Accepted simplification** is named explicitly so the reader knows it's deliberate.
- **Reuse / Do NOT reuse / New** trio forces a decision per existing artifact.
- **Open questions** are numbered with `Proposed: / Alternative: / Need user call.`
