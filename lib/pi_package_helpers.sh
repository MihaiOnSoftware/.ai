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

# ---------------------------------------------------------------------------
# TEMPORARY WORKAROUND — pi-subagents#334
# ---------------------------------------------------------------------------
# pi-subagents' detached async/parallel runner is a separate `node + jiti`
# process that value-imports `@earendil-works/pi-coding-agent`
# (src/shared/utils.ts:8, on the runner's load path since pi-subagents 0.31.0).
# pi deliberately does NOT install host packages on disk as peer deps
# (pi CHANGELOG #4907): in-process extensions get the module via loader
# aliases, but the out-of-process runner cannot — so it crashes at import with
# MODULE_NOT_FOUND and every async/parallel subagent "exits before writing a
# result". Sync (in-process) subagents are unaffected.
#
# Symlinking the host pi's copy into pi's npm tree lets the runner resolve it
# via a node_modules walk. NOTE: NODE_PATH is NOT sufficient — under jiti it
# then fails with ERR_PACKAGE_PATH_NOT_EXPORTED on the package's import-only
# `exports`.
#
# The proper fix belongs upstream (resolve the runner's @earendil-works/*
# imports from the spawn config's piPackageRoot). REMOVE this workaround — this
# block plus install_pi_subagents_workaround.sh / its uninstall counterpart and
# the calls in install.sh / uninstall.sh — once that ships:
# https://github.com/nicobailon/pi-subagents/issues/334
# ---------------------------------------------------------------------------

# Resolve the host pi's @earendil-works/pi-coding-agent package root from the
# `pi` binary on PATH (works regardless of the global npm prefix). Echoes the
# absolute path, or nothing if it cannot be resolved. node is always present
# because pi runs on it.
resolve_pi_coding_agent_root() {
    local pi_bin
    pi_bin="$(command -v pi || true)"
    if [ -z "$pi_bin" ]; then
        return 0
    fi
    node -e '
        const fs = require("fs"), p = require("path");
        try {
            const root = p.dirname(p.dirname(fs.realpathSync(process.argv[1])));
            const pkg = JSON.parse(fs.readFileSync(p.join(root, "package.json"), "utf8"));
            if (pkg.name !== "@earendil-works/pi-coding-agent") process.exit(4);
            process.stdout.write(root);
        } catch (e) { process.exit(3); }
    ' "$pi_bin" 2>/dev/null || true
}

install_pi_subagents_workaround() {
    local link_path="$1"
    local pca_root
    pca_root="$(resolve_pi_coding_agent_root)"
    if [ -z "$pca_root" ]; then
        log_warning "  Skipping pi-subagents#334 workaround: could not resolve @earendil-works/pi-coding-agent (is 'pi' on PATH?)"
        return 0
    fi
    validate_source_dir "$pca_root" "pi-coding-agent package"
    create_symlink "$link_path" "$pca_root"
}

uninstall_pi_subagents_workaround() {
    local link_path="$1"
    local pca_root
    pca_root="$(resolve_pi_coding_agent_root)"
    if [ -n "$pca_root" ]; then
        uninstall_symlink "$link_path" "$pca_root"
    elif [ -L "$link_path" ]; then
        rm "$link_path"
        log_success "Removed symlink: $link_path"
    else
        log_info "Skipping path: Does not exist or not a managed symlink"
        echo "  Path: $link_path"
    fi
}
