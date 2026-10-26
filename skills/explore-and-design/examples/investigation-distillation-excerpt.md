# Example: wip findings → ticket comment

A spike's wip doc is written for the next session that has to re-run or extend it: IDs, endpoints, run numbers, verbatim probe output. The ticket comment is written for teammates who know the systems but didn't do the spike. Same findings, different reader.

This pair comes from a spike on how Workato's dynamic field mapping behaves at runtime.

## The wip doc (excerpt)

`~/.ai/wip/api-828-spike-2026-10-09.md`:

> **Method**: live runs against a purpose-built test recipe in the Workato dev partner workspace (`8499350`), same Mapper + data-model carrier as the decided design. 10 jobs fired, step outputs observed via an instrumented stop step whose reason interpolates datapill formulas.
>
> | # | Check | Verdict |
> |---|---|---|
> | 1 | Boolean coercion | **No coercion. Value stays the string `"false"`/`"true"`.** Scope reframed by Mihai mid-spike: the data model encodes booleans as string selects (no `boolean`-typed field exists in model 144073). Runtime proof: `== 'false'` → true, `== false` → false, `.present?` on `"false"` → **true**. |
> | 3 | Builder-input vs field-map precedence | **Field-map static wins, per-field, with builder fallback.** Builder value `builder-value` + static `fieldmap-value` → step outputs `fieldmap-value`. Removing the field's entry → `builder-value` resurfaces. Empty-string static → empty wins. |
>
> ```
> eq_str_false=true    # value == 'false'  → it is the STRING "false"
> eq_bool_false=false  # value == false    → NOT a real boolean
> present=true         # "false".present?  → truthy
> ```
>
> Privileges: recipe start/stop returned 401 `missing_privilege` at spike start; granted mid-session. …

## The Linear comment (as posted, trimmed)

> **Spike done. All 4 checks answered against a live test recipe (82950892 in the dev partner workspace, left in place for future testing).**
>
> **1. Boolean coercion — values stay strings, so truthiness checks are unsafe.**
> The Mapper step outputs exactly the string we stored, with no type conversion. A stored `"false"` comes out as the string `"false"`, and any truthiness-style check treats it as true. A customer picking "off" would silently get "on". Rule for recipe authors: boolean config must always be consumed with an explicit string comparison (`== "true"`), never a presence or truthy check. …
>
> **3. Builder value vs field map — the field map wins.**
> When a field has both a builder value and a field-map entry, the job uses the field-map entry. Fields without an entry fall back to their builder value, so builder values act as author defaults. An empty-string entry beats the builder value too, so a customer can clear a field. The flip side: if we skip writing an entry for a field we meant to control, the author's leftover value goes out with the job.
>
> …
>
> Full details and reproduction steps are in my spike notes. One minor loose end: if the data model later drops a field that still has a field-map entry, the stale entry persists in the map. We didn't test what a job does with it, so our config writer should prune entries for removed fields.

## What changed between the two

- **Headings state the answer**, not the question: "values stay strings, so truthiness checks are unsafe".
- **Consequences replace probe output.** `present=true` becomes "a customer picking 'off' would silently get 'on'".
- **Each finding ends in a rule or implication** for the people building on it.
- **Process details are gone**: run numbers, the mid-spike privilege grant, who reframed which check, the instrumentation trick. The one artifact a teammate can reuse (the test recipe ID) stays.
- **The untested edge is named** as a loose end with a concrete mitigation, not buried.
