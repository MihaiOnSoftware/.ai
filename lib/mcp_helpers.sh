#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/symlink_helpers.sh"
source "$SCRIPT_DIR/paths.sh"

# MCP servers are declared in a standard mcpServers JSON file (no secrets) and
# installed into Claude at user scope via the maintained `claude mcp` CLI, which
# handles merge/validation/OAuth. pi then reads them through pi-mcp-adapter's
# "claude-code" compatibility import, registered in $PI_MCP_CONFIG_PATH.
#
# An optional "piOverrides" map carries pi-mcp-adapter-only settings (e.g.
# excludeTools) that Claude's config can't hold; these are merged into
# $PI_MCP_CONFIG_PATH as partial server entries layered onto the imported server.

_require_claude() {
    if ! command -v claude >/dev/null 2>&1; then
        log_error "✗ Error: claude CLI not found on PATH — required to install MCP servers"
        exit 1
    fi
}

# Emit "<action>\t<name>\t<compact-json>" per server, where action is
# ADD (not in Claude), UPDATE (def changed), or SKIP (matches). Compares the
# fields we manage against Claude's user config so existing auth is preserved
# for unchanged servers.
_mcp_plan() {
    local source_file="$1"
    node -e '
const fs = require("fs");
const [src, claudePath] = process.argv.slice(1);
const want = (JSON.parse(fs.readFileSync(src, "utf8")).mcpServers) || {};
let have = {};
if (fs.existsSync(claudePath)) {
  try { have = (JSON.parse(fs.readFileSync(claudePath, "utf8")).mcpServers) || {}; } catch (e) {}
}
const matches = (w, h) => {
  if (!h) return false;
  for (const k of Object.keys(w)) {
    if (JSON.stringify(h[k]) !== JSON.stringify(w[k])) return false;
  }
  return true;
};
for (const name of Object.keys(want)) {
  const action = have[name] === undefined ? "ADD" : (matches(want[name], have[name]) ? "SKIP" : "UPDATE");
  console.log([action, name, JSON.stringify(want[name])].join("\t"));
}
' "$source_file" "$CLAUDE_USER_CONFIG"
}

# Emit server names that carry piOverrides.
_mcp_override_names() {
    node -e '
const fs = require("fs");
const o = (JSON.parse(fs.readFileSync(process.argv[1], "utf8")).piOverrides) || {};
for (const n of Object.keys(o)) console.log(n);
' "$1"
}

# Merge the claude-code import + any piOverrides from the source file into
# $PI_MCP_CONFIG_PATH, preserving other keys. Refuses to touch an unparseable file.
_apply_pi_config() {
    local source_file="$1"
    local result
    result="$(node -e '
const fs = require("fs");
const path = require("path");
const [src, dst] = process.argv.slice(1);
const host = "claude-code";
const source = JSON.parse(fs.readFileSync(src, "utf8"));
const overrides = source.piOverrides || {};

let cfg = {};
if (fs.existsSync(dst)) {
  try { cfg = JSON.parse(fs.readFileSync(dst, "utf8")); }
  catch (e) { console.log("UNPARSEABLE"); process.exit(0); }
}
if (!Array.isArray(cfg.imports)) cfg.imports = [];
let importAdded = false;
if (!cfg.imports.includes(host)) { cfg.imports.push(host); importAdded = true; }

if (typeof cfg.mcpServers !== "object" || cfg.mcpServers === null) cfg.mcpServers = {};
const applied = [];
for (const name of Object.keys(overrides)) {
  cfg.mcpServers[name] = { ...(cfg.mcpServers[name] || {}), ...overrides[name] };
  applied.push(name);
}

fs.mkdirSync(path.dirname(dst), { recursive: true });
fs.writeFileSync(dst, JSON.stringify(cfg, null, 2) + "\n");
console.log((importAdded ? "IMPORT_ADDED" : "IMPORT_PRESENT") + "\t" + applied.join(","));
' "$source_file" "$PI_MCP_CONFIG_PATH")"

    if [ "$result" = "UNPARSEABLE" ]; then
        log_error "✗ Error: $PI_MCP_CONFIG_PATH is not valid JSON — leaving it untouched"
        exit 3
    fi
    local importflag applied
    importflag="${result%%$'\t'*}"
    applied="${result#*$'\t'}"
    case "$importflag" in
        IMPORT_ADDED)   log_info "  ➕ Registered claude-code import in $PI_MCP_CONFIG_PATH" ;;
        IMPORT_PRESENT) log_success "  ✓ pi already imports claude-code" ;;
    esac
    if [ -n "$applied" ]; then
        log_info "  ⚙️  Applied pi overrides: $applied"
    fi
}

install_mcp() {
    local source_file="$1"

    validate_source_file "$source_file" "MCP config file"
    _require_claude

    MCP_COUNT_ADDED=0
    MCP_COUNT_UPDATED=0
    MCP_COUNT_PRESENT=0
    while IFS=$'\t' read -r action name json; do
        [ -z "$action" ] && continue
        case "$action" in
            ADD)
                log_info "  ➕ Adding server to Claude (user scope): $name"
                claude mcp add-json "$name" "$json" -s user >/dev/null
                MCP_COUNT_ADDED=$((MCP_COUNT_ADDED + 1)) ;;
            UPDATE)
                log_info "  ♻️  Updating changed server in Claude: $name (re-auth may be needed)"
                claude mcp remove "$name" >/dev/null 2>&1 || true
                claude mcp add-json "$name" "$json" -s user >/dev/null
                MCP_COUNT_UPDATED=$((MCP_COUNT_UPDATED + 1)) ;;
            SKIP)
                log_success "  ✓ Server already current in Claude: $name"
                MCP_COUNT_PRESENT=$((MCP_COUNT_PRESENT + 1)) ;;
        esac
    done <<< "$(_mcp_plan "$source_file")"

    _apply_pi_config "$source_file"
}

uninstall_mcp() {
    local source_file="$1"

    validate_source_file "$source_file" "MCP config file"
    _require_claude

    local entries
    entries="$(_mcp_servers_tsv "$source_file")"

    MCP_COUNT_REMOVED=0
    MCP_COUNT_SKIPPED=0
    while IFS=$'\t' read -r name json; do
        [ -z "$name" ] && continue
        if claude mcp get "$name" >/dev/null 2>&1; then
            log_info "  ➖ Removing server from Claude: $name"
            claude mcp remove "$name" >/dev/null 2>&1 || log_warning "  Could not remove $name"
            MCP_COUNT_REMOVED=$((MCP_COUNT_REMOVED + 1))
        else
            log_info "  Skipping server: $name (not in Claude)"
            MCP_COUNT_SKIPPED=$((MCP_COUNT_SKIPPED + 1))
        fi
    done <<< "$entries"

    _cleanup_pi_config "$source_file"
}

# List "<name>\t<compact-json>" for each declared server.
_mcp_servers_tsv() {
    node -e '
const fs = require("fs");
const s = (JSON.parse(fs.readFileSync(process.argv[1], "utf8")).mcpServers) || {};
for (const n of Object.keys(s)) console.log(n + "\t" + JSON.stringify(s[n]));
' "$1"
}

# Remove our piOverrides from $PI_MCP_CONFIG_PATH, and drop the claude-code
# import if no local Claude servers remain to import.
_cleanup_pi_config() {
    local source_file="$1"
    [ -f "$PI_MCP_CONFIG_PATH" ] || { log_info "  No pi MCP config to clean up"; return 0; }

    local result
    result="$(node -e '
const fs = require("fs");
const [src, dst, claudePath] = process.argv.slice(1);
const source = JSON.parse(fs.readFileSync(src, "utf8"));
const overrideNames = Object.keys(source.piOverrides || {});

let cfg;
try { cfg = JSON.parse(fs.readFileSync(dst, "utf8")); }
catch (e) { console.log("UNPARSEABLE"); process.exit(0); }

const removed = [];
if (cfg.mcpServers && typeof cfg.mcpServers === "object") {
  for (const n of overrideNames) {
    if (cfg.mcpServers[n] !== undefined) { delete cfg.mcpServers[n]; removed.push(n); }
  }
  if (Object.keys(cfg.mcpServers).length === 0) delete cfg.mcpServers;
}

// Drop the import if Claude has no local servers left to import.
let claudeServers = 0;
if (fs.existsSync(claudePath)) {
  try { claudeServers = Object.keys(JSON.parse(fs.readFileSync(claudePath, "utf8")).mcpServers || {}).length; }
  catch (e) { claudeServers = -1; }
}
let importDropped = false;
if (claudeServers === 0 && Array.isArray(cfg.imports)) {
  cfg.imports = cfg.imports.filter((h) => h !== "claude-code");
  if (cfg.imports.length === 0) delete cfg.imports;
  importDropped = true;
}

fs.writeFileSync(dst, JSON.stringify(cfg, null, 2) + "\n");
console.log(removed.join(",") + "\t" + (importDropped ? "IMPORT_DROPPED" : "IMPORT_KEPT"));
' "$source_file" "$PI_MCP_CONFIG_PATH" "$CLAUDE_USER_CONFIG")"

    if [ "$result" = "UNPARSEABLE" ]; then
        log_warning "  $PI_MCP_CONFIG_PATH is not valid JSON — left untouched"
        return 0
    fi
    local removed importflag
    removed="${result%%$'\t'*}"
    importflag="${result#*$'\t'}"
    [ -n "$removed" ] && log_info "  ⚙️  Removed pi overrides: $removed"
    case "$importflag" in
        IMPORT_DROPPED) log_info "  ➖ Removed claude-code import (no local Claude servers remain)" ;;
        IMPORT_KEPT)    log_info "  Leaving claude-code import (other Claude servers still present)" ;;
    esac
}
