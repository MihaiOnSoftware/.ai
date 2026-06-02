#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/symlink_helpers.sh"
source "$SCRIPT_DIR/paths.sh"

# MCP servers are declared once in a canonical mcpServers JSON file (pi-mcp-adapter
# schema, no secrets) and *generated* into each host's native MCP config:
#
#   - pi:       $PI_MCP_CONFIG_PATH        — pi-mcp-adapter, "mcpServers" map,
#                                            carries pi-only fields verbatim
#                                            (e.g. excludeTools, oauth).
#   - OpenCode: $OPENCODE_MCP_CONFIG_PATH  — opencode.json "mcp" block, each
#                                            server translated to {type:"remote",
#                                            url, enabled, headers?, oauth?}.
#
# Claude is intentionally NOT emitted right now. To restore it, add a
# `_claude_apply` / `_claude_remove` pair below and a line in install_mcp /
# uninstall_mcp — the rest of the flow is host-agnostic.
#
# Translation notes:
#   - OpenCode has no reliable per-tool filter, so `excludeTools` is dropped for
#     OpenCode (warned). Prefer server-side filtering in the `url` (e.g. a
#     server's own omit/toolsets params) when you need to shrink the surface for
#     every host at once.
#   - No secrets live in the canonical file. Each host runs its own OAuth on
#     first use; tokens are stored per-host, outside the repo.
#
# Secret injection:
#   A server's `oauth` block may reference env vars with ${VAR} / $env:VAR (e.g.
#   a pre-registered Slack app's client id/secret). pi-mcp-adapter does NOT
#   interpolate inside `oauth` at runtime, so the emitters resolve those refs
#   from the install environment and write the real values into the generated
#   (out-of-repo) host configs. The canonical mcp.json only ever holds the
#   ${VAR} placeholders. If a referenced var is unset, that server is SKIPPED
#   with a warning (other servers still install).

# Shared JS resolver injected into each emitter: interpolate ${VAR}/$env:VAR in
# an oauth object from the environment, reporting any unset names.
_OAUTH_RESOLVER_JS='
function resolveOauth(oauth) {
  const missing = new Set();
  const re = /\$\{(\w+)\}|\$env:(\w+)/g;
  const res = (v) => {
    if (typeof v === "string") return v.replace(re, (m, a, b) => {
      const n = a || b; const val = process.env[n];
      if (val === undefined || val === "") { missing.add(n); return m; }
      return val;
    });
    if (Array.isArray(v)) return v.map(res);
    if (v && typeof v === "object") { const o = {}; for (const k of Object.keys(v)) o[k] = res(v[k]); return o; }
    return v;
  };
  return { resolved: res(oauth), missing: [...missing] };
}
'

# ---------------------------------------------------------------------------
# pi emitter — merge canonical servers into $PI_MCP_CONFIG_PATH verbatim.
# ---------------------------------------------------------------------------
# Prints "<comma-separated names>" applied, or "UNPARSEABLE" if the existing
# destination is not valid JSON (left untouched in that case).
_pi_apply() {
    node -e "$_OAUTH_RESOLVER_JS"'
const fs = require("fs");
const path = require("path");
const [src, dst] = process.argv.slice(1);
const servers = (JSON.parse(fs.readFileSync(src, "utf8")).mcpServers) || {};

let cfg = {};
if (fs.existsSync(dst)) {
  try { cfg = JSON.parse(fs.readFileSync(dst, "utf8")); }
  catch (e) { console.log("UNPARSEABLE"); process.exit(0); }
}

// Dropping Claude: stop importing its servers into pi.
if (Array.isArray(cfg.imports)) {
  cfg.imports = cfg.imports.filter((h) => h !== "claude-code");
  if (cfg.imports.length === 0) delete cfg.imports;
}

if (typeof cfg.mcpServers !== "object" || cfg.mcpServers === null) cfg.mcpServers = {};
const applied = [], skipped = [];
for (const [name, def] of Object.entries(servers)) {
  const entry = { ...def }; // pi schema IS the canonical schema
  if (def.oauth) {
    const { resolved, missing } = resolveOauth(def.oauth);
    if (missing.length) { skipped.push(name + " (set " + missing.join(", ") + ")"); continue; }
    entry.oauth = resolved;
  }
  cfg.mcpServers[name] = entry;
  applied.push(name);
}

fs.mkdirSync(path.dirname(dst), { recursive: true });
fs.writeFileSync(dst, JSON.stringify(cfg, null, 2) + "\n");
console.log(applied.join(",") + "\t" + skipped.join("; "));
' "$1" "$2"
}

# Remove the canonical servers from $PI_MCP_CONFIG_PATH. Prints removed names.
_pi_remove() {
    node -e '
const fs = require("fs");
const [src, dst] = process.argv.slice(1);
const names = Object.keys((JSON.parse(fs.readFileSync(src, "utf8")).mcpServers) || {});
if (!fs.existsSync(dst)) { console.log(""); process.exit(0); }
let cfg;
try { cfg = JSON.parse(fs.readFileSync(dst, "utf8")); }
catch (e) { console.log("UNPARSEABLE"); process.exit(0); }
const removed = [];
if (cfg.mcpServers && typeof cfg.mcpServers === "object") {
  for (const n of names) {
    if (cfg.mcpServers[n] !== undefined) { delete cfg.mcpServers[n]; removed.push(n); }
  }
  if (Object.keys(cfg.mcpServers).length === 0) delete cfg.mcpServers;
}
fs.writeFileSync(dst, JSON.stringify(cfg, null, 2) + "\n");
console.log(removed.join(","));
' "$1" "$2"
}

# ---------------------------------------------------------------------------
# OpenCode emitter — translate canonical servers into the opencode.json "mcp"
# block, preserving every other key in the file.
# ---------------------------------------------------------------------------
# Prints "<applied names>\t<names whose excludeTools was dropped>", or
# "UNPARSEABLE".
_opencode_apply() {
    node -e "$_OAUTH_RESOLVER_JS"'
const fs = require("fs");
const path = require("path");
const [src, dst] = process.argv.slice(1);
const servers = (JSON.parse(fs.readFileSync(src, "utf8")).mcpServers) || {};

let cfg = {};
if (fs.existsSync(dst)) {
  try { cfg = JSON.parse(fs.readFileSync(dst, "utf8")); }
  catch (e) { console.log("UNPARSEABLE"); process.exit(0); }
}
if (!cfg["$schema"]) cfg["$schema"] = "https://opencode.ai/config.json";
if (typeof cfg.mcp !== "object" || cfg.mcp === null) cfg.mcp = {};

const applied = [], droppedExclude = [], skipped = [];
for (const [name, def] of Object.entries(servers)) {
  const oc = { type: "remote", url: def.url, enabled: true };
  if (def.headers) oc.headers = def.headers;
  if (def.oauth) {
    const { resolved, missing } = resolveOauth(def.oauth);
    if (missing.length) { skipped.push(name + " (set " + missing.join(", ") + ")"); continue; }
    oc.oauth = resolved;
  }
  cfg.mcp[name] = oc;
  applied.push(name);
  if (Array.isArray(def.excludeTools) && def.excludeTools.length) droppedExclude.push(name);
}

fs.mkdirSync(path.dirname(dst), { recursive: true });
fs.writeFileSync(dst, JSON.stringify(cfg, null, 2) + "\n");
console.log(applied.join(",") + "\t" + droppedExclude.join(",") + "\t" + skipped.join("; "));
' "$1" "$2"
}

# Remove the canonical servers from the opencode.json "mcp" block. Prints names.
_opencode_remove() {
    node -e '
const fs = require("fs");
const [src, dst] = process.argv.slice(1);
const names = Object.keys((JSON.parse(fs.readFileSync(src, "utf8")).mcpServers) || {});
if (!fs.existsSync(dst)) { console.log(""); process.exit(0); }
let cfg;
try { cfg = JSON.parse(fs.readFileSync(dst, "utf8")); }
catch (e) { console.log("UNPARSEABLE"); process.exit(0); }
const removed = [];
if (cfg.mcp && typeof cfg.mcp === "object") {
  for (const n of names) {
    if (cfg.mcp[n] !== undefined) { delete cfg.mcp[n]; removed.push(n); }
  }
  if (Object.keys(cfg.mcp).length === 0) delete cfg.mcp;
}
fs.writeFileSync(dst, JSON.stringify(cfg, null, 2) + "\n");
console.log(removed.join(","));
' "$1" "$2"
}

# ---------------------------------------------------------------------------
# Public entry points
# ---------------------------------------------------------------------------
install_mcp() {
    local source_file="$1"
    validate_source_file "$source_file" "MCP config file"

    MCP_PI_APPLIED=""
    MCP_OPENCODE_APPLIED=""

    # --- pi ---
    log_info "  Generating pi config: $PI_MCP_CONFIG_PATH"
    local r
    r="$(_pi_apply "$source_file" "$PI_MCP_CONFIG_PATH")"
    if [ "$r" = "UNPARSEABLE" ]; then
        log_error "✗ Error: $PI_MCP_CONFIG_PATH is not valid JSON — leaving it untouched"
        exit 3
    fi
    local pi_applied pi_skipped
    pi_applied="${r%%$'\t'*}"
    pi_skipped="${r#*$'\t'}"
    MCP_PI_APPLIED="$pi_applied"
    [ -n "$pi_applied" ] && log_success "  ✓ pi servers: $pi_applied"
    [ -n "$pi_skipped" ] && log_warning "  ⚠ pi servers skipped (missing OAuth env): $pi_skipped"

    # --- OpenCode ---
    log_info "  Generating OpenCode config: $OPENCODE_MCP_CONFIG_PATH"
    r="$(_opencode_apply "$source_file" "$OPENCODE_MCP_CONFIG_PATH")"
    if [ "$r" = "UNPARSEABLE" ]; then
        log_error "✗ Error: $OPENCODE_MCP_CONFIG_PATH is not valid JSON — leaving it untouched"
        exit 3
    fi
    local oc_applied oc_rest oc_dropped oc_skipped
    oc_applied="${r%%$'\t'*}"
    oc_rest="${r#*$'\t'}"
    oc_dropped="${oc_rest%%$'\t'*}"
    oc_skipped="${oc_rest#*$'\t'}"
    MCP_OPENCODE_APPLIED="$oc_applied"
    [ -n "$oc_applied" ] && log_success "  ✓ OpenCode servers: $oc_applied"
    if [ -n "$oc_dropped" ]; then
        log_warning "  ⚠ excludeTools not supported by OpenCode — full tool surface exposed for: $oc_dropped"
    fi
    [ -n "$oc_skipped" ] && log_warning "  ⚠ OpenCode servers skipped (missing OAuth env): $oc_skipped"
}

uninstall_mcp() {
    local source_file="$1"
    validate_source_file "$source_file" "MCP config file"

    MCP_PI_REMOVED=""
    MCP_OPENCODE_REMOVED=""

    local r
    r="$(_pi_remove "$source_file" "$PI_MCP_CONFIG_PATH")"
    if [ "$r" = "UNPARSEABLE" ]; then
        log_warning "  $PI_MCP_CONFIG_PATH is not valid JSON — left untouched"
    else
        MCP_PI_REMOVED="$r"
        [ -n "$r" ] && log_info "  ➖ Removed pi servers: $r"
    fi

    r="$(_opencode_remove "$source_file" "$OPENCODE_MCP_CONFIG_PATH")"
    if [ "$r" = "UNPARSEABLE" ]; then
        log_warning "  $OPENCODE_MCP_CONFIG_PATH is not valid JSON — left untouched"
    else
        MCP_OPENCODE_REMOVED="$r"
        [ -n "$r" ] && log_info "  ➖ Removed OpenCode servers: $r"
    fi
}
