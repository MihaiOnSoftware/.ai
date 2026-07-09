#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/symlink_helpers.sh"

# Settings are declared under the "settings" key of pi.jsonc and merged into
# ~/.pi/agent/settings.json. Only the top-level keys declared in pi.jsonc are
# managed: install deep-merges them (declared values win), uninstall removes
# them entirely. Everything else in settings.json is left untouched.

PI_SETTINGS_FILE="${PI_SETTINGS_FILE:-$HOME/.pi/agent/settings.json}"

_pi_settings_node() {
    local source_file="$1"
    local mode="$2"
    node -e "
const fs = require('fs');
const text = fs.readFileSync('$source_file', 'utf8')
  .replace(/\/\/.*/g, '')
  .replace(/\/\*[\s\S]*?\*\//g, '');
const declared = (JSON.parse(text).settings) || {};
const keys = Object.keys(declared);
if (keys.length === 0) { console.log('none'); process.exit(0); }

const settingsPath = '$PI_SETTINGS_FILE';
let settings = {};
try { settings = JSON.parse(fs.readFileSync(settingsPath, 'utf8')); } catch (e) {}

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
fs.writeFileSync(settingsPath, JSON.stringify(settings, null, 2) + '\n');
console.log(keys.join(', '));
"
}

install_pi_settings() {
    local source_file="$1"
    validate_source_file "$source_file" "pi settings file"
    PI_SETTINGS_APPLIED="$(_pi_settings_node "$source_file" install)"
}

uninstall_pi_settings() {
    local source_file="$1"
    validate_source_file "$source_file" "pi settings file"
    PI_SETTINGS_APPLIED="$(_pi_settings_node "$source_file" uninstall)"
}
