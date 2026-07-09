#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/symlink_helpers.sh"

# Settings are declared under the "settings" key of pi.jsonc and merged into
# ~/.pi/agent/settings.json. Only the top-level keys declared in pi.jsonc are
# managed: install deep-merges them (declared values win), uninstall removes
# them entirely. Everything else in settings.json is left untouched.
#
# Write safety: the result is written to a temp file first and validated as
# JSON; only then is the original moved to settings.json.<mode>-<date>.bak
# (e.g. settings.json.install-20260709.bak) and the temp file moved into
# place. A corrupt existing settings file aborts before any change.

PI_SETTINGS_FILE="${PI_SETTINGS_FILE:-$HOME/.pi/agent/settings.json}"

_pi_settings_validate_json() {
    node -e "JSON.parse(require('fs').readFileSync('$1', 'utf8'))" 2>/dev/null
}

_pi_settings_node() {
    local source_file="$1"
    local mode="$2"
    local out_file="$3"
    node -e "
const fs = require('fs');
const text = fs.readFileSync('$source_file', 'utf8')
  .replace(/\/\/.*/g, '')
  .replace(/\/\*[\s\S]*?\*\//g, '');
const declared = (JSON.parse(text).settings) || {};
const keys = Object.keys(declared);
if (keys.length === 0) { console.log('none'); process.exit(0); }

let settings = {};
try { settings = JSON.parse(fs.readFileSync('$PI_SETTINGS_FILE', 'utf8')); } catch (e) {}

const isObj = (v) => v && typeof v === 'object' && !Array.isArray(v);
const deepMerge = (base, over) => {
  const out = { ...base };
  for (const [k, v] of Object.entries(over)) {
    out[k] = isObj(v) && isObj(base[k]) ? deepMerge(base[k], v) : v;
  }
  return out;
};

if ('$mode' === 'install') {
  for (const k of keys) {
    settings[k] = isObj(declared[k]) && isObj(settings[k]) ? deepMerge(settings[k], declared[k]) : declared[k];
  }
} else {
  for (const k of keys) delete settings[k];
}
fs.writeFileSync('$out_file', JSON.stringify(settings, null, 2) + '\n');
console.log(keys.join(', '));
"
}

_pi_settings_apply() {
    local source_file="$1"
    local mode="$2"

    validate_source_file "$source_file" "pi settings file"

    if [ -f "$PI_SETTINGS_FILE" ] && ! _pi_settings_validate_json "$PI_SETTINGS_FILE"; then
        log_error "Existing $PI_SETTINGS_FILE is not valid JSON — aborting without changes"
        return 1
    fi

    local tmp_file="$PI_SETTINGS_FILE.tmp.$$"
    PI_SETTINGS_APPLIED="$(_pi_settings_node "$source_file" "$mode" "$tmp_file")" || { rm -f "$tmp_file"; return 1; }

    if [ "$PI_SETTINGS_APPLIED" = "none" ]; then
        rm -f "$tmp_file"
        return 0
    fi

    if ! _pi_settings_validate_json "$tmp_file"; then
        log_error "Merged settings failed JSON validation — aborting, $PI_SETTINGS_FILE unchanged"
        rm -f "$tmp_file"
        return 1
    fi

    if [ -f "$PI_SETTINGS_FILE" ]; then
        mv "$PI_SETTINGS_FILE" "$PI_SETTINGS_FILE.$mode-$(date +%Y%m%d).bak"
    fi
    mv "$tmp_file" "$PI_SETTINGS_FILE"
}

install_pi_settings() {
    _pi_settings_apply "$1" install
}

uninstall_pi_settings() {
    _pi_settings_apply "$1" uninstall
}
