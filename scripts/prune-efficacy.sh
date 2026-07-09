#!/usr/bin/env bash

# Measures pi-condense pruning effectiveness for a local-day date range.
# Run once for a baseline range and once for a trial range, then compare.
#
# Usage:
#   prune-efficacy.sh <from-date> [to-date]     # dates as YYYY-MM-DD
#
# Metrics (MAIN sessions are where pruning matters; subagents are disposable):
#   - $/turn and cacheRead tokens/turn  — the carry cost pruning should reduce
#   - prune summaries injected          — evidence pruning is firing
#   - context_tree_query calls          — recovery rate; high = over-pruning

set -euo pipefail

FROM="${1:?Usage: prune-efficacy.sh <from-date> [to-date]}"
TO="${2:-$FROM}"

python3 - "$FROM" "$TO" <<'PY'
import json, os, sys
from datetime import date, datetime, time, timedelta, timezone

frm, to = date.fromisoformat(sys.argv[1]), date.fromisoformat(sys.argv[2])
local_tz = datetime.now().astimezone().tzinfo
ws = datetime.combine(frm, time.min, tzinfo=local_tz).astimezone(timezone.utc)
we = datetime.combine(to + timedelta(days=1), time.min, tzinfo=local_tz).astimezone(timezone.utc)

SD = os.path.expanduser(os.environ.get("PI_SESSIONS_DIR", "~/.pi/agent/sessions"))
buckets = {k: {"cost": 0.0, "turns": 0, "cacheRead": 0} for k in ("main", "child")}
prune_summaries = recoveries = 0
seen = set()

for dp, _, fs in os.walk(SD):
    for fn in fs:
        if not fn.endswith(".jsonl"):
            continue
        fp = os.path.join(dp, fn)
        if os.path.getmtime(fp) < ws.timestamp():
            continue
        kind = "child" if len(os.path.relpath(fp, SD).split(os.sep)) > 3 else "main"
        for line in open(fp):
            if not line.strip():
                continue
            try:
                e = json.loads(line)
            except json.JSONDecodeError:
                continue
            try:
                ts = datetime.fromisoformat(e.get("timestamp", "").replace("Z", "+00:00"))
            except ValueError:
                continue
            if not (ws <= ts < we):
                continue
            if e.get("type") == "custom_message" and e.get("customType") == "context-prune-summary":
                prune_summaries += 1
            m = e.get("message")
            if not isinstance(m, dict):
                continue
            if '"context_tree_query"' in line and m.get("role") == "assistant":
                recoveries += 1
            u = m.get("usage")
            if not isinstance(u, dict):
                continue
            rid = m.get("responseId")
            key = "r:" + rid if rid else f"e:{fp}:{e.get('id')}"
            if key in seen:
                continue
            seen.add(key)
            b = buckets[kind]
            b["cost"] += u.get("cost", {}).get("total", 0)
            b["turns"] += 1
            b["cacheRead"] += u.get("cacheRead", 0)

print(f"Prune efficacy  {frm} -> {to}")
print("-" * 56)
for kind, label in (("main", "MAIN sessions"), ("child", "Subagents")):
    b = buckets[kind]
    per_turn = b["cost"] / b["turns"] if b["turns"] else 0
    cr_per_turn = b["cacheRead"] / b["turns"] / 1e6 if b["turns"] else 0
    print(f"{label:14s} ${b['cost']:8.2f}  turns={b['turns']:6d}  "
          f"$/turn={per_turn:6.4f}  cacheRead/turn={cr_per_turn:5.2f}M")
print(f"{'Pruning':14s} summaries injected={prune_summaries}  context_tree_query recoveries={recoveries}")
PY
