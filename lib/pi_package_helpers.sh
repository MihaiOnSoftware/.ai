#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/symlink_helpers.sh"

# Read installed packages from ~/.pi/agent/settings.json.
# Avoids calling `pi list` which hangs in 0.79+ when extensions are loaded
# (earendil-works/pi#4617).
read_installed_packages() {
    node -e "
    try {
      const s = JSON.parse(require('fs').readFileSync(process.env.HOME + '/.pi/agent/settings.json', 'utf8'));
      console.log((s.packages || []).join('\n'));
    } catch(e) {}
    " 2>/dev/null || true
}

# Parse a pi.jsonc into TSV lines: <install-spec><TAB><identity-spec>
# Strips // and /* */ comments, then reads the .packages[] array.
# identity-spec keeps the source prefix (npm:/git:) but drops any trailing
# @version/@ref, while preserving a leading @scope. It matches what `pi list`
# prints and what `pi remove` expects (e.g. npm:@scope/pkg@1.2.3 -> npm:@scope/pkg).
parse_pi_packages() {
    local source_file="$1"
    node -e "
const fs = require('fs');
const text = fs.readFileSync('$source_file', 'utf8')
  .replace(/\/\/.*/g, '')
  .replace(/\/\*[\s\S]*?\*\//g, '');
const obj = JSON.parse(text);
for (const spec of (obj.packages || [])) {
  const m = spec.match(/^(npm:|git:)?([\s\S]*)\$/);
  const prefix = m[1] || '';
  const body = m[2];
  const at = body.lastIndexOf('@');      // >0 means trailing @version/@ref, not a leading @scope
  const core = at > 0 ? body.slice(0, at) : body;
  console.log([spec, prefix + core].join('\t'));
}
"
}

install_pi_packages() {
    local source_file="$1"

    validate_source_file "$source_file" "pi packages file"

    local entries installed
    entries="$(parse_pi_packages "$source_file")"
    installed="$(read_installed_packages)"

    while IFS=$'\t' read -r spec idspec; do
        [ -z "$spec" ] && continue
        if echo "$installed" | grep -qF "$idspec"; then
            log_success "✓ Package already installed: $spec"
            COUNT_CORRECT=$((COUNT_CORRECT + 1))
        else
            log_info "➕ Installing package: $spec"
            pi install "$spec"
            COUNT_CREATED=$((COUNT_CREATED + 1))
        fi
    done <<< "$entries"
}

uninstall_pi_packages() {
    local source_file="$1"

    validate_source_file "$source_file" "pi packages file"

    local entries installed
    entries="$(parse_pi_packages "$source_file")"
    installed="$(read_installed_packages)"

    while IFS=$'\t' read -r spec idspec; do
        [ -z "$spec" ] && continue
        if echo "$installed" | grep -qF "$idspec"; then
            log_info "  Removing package: $idspec"
            pi remove "$idspec" || log_warning "  Could not remove $idspec"
        else
            log_info "  Skipping package: $idspec (not installed)"
        fi
    done <<< "$entries"
}
