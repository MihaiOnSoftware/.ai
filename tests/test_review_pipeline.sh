#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LENS_REVIEWERS=(mihai-pattern-review-agent mihai-rules-review-agent)

PASS=0
FAIL=0

pass() { echo "✓ $1"; PASS=$((PASS + 1)); }
fail() { echo "✗ $1"; FAIL=$((FAIL + 1)); }

assert() {
    local desc="$1"; shift
    if "$@" >/dev/null 2>&1; then pass "$desc"; else fail "$desc"; fi
}

SANDBOX="$(mktemp -d)"
trap 'rm -rf "$SANDBOX"' EXIT

# ── Checks ────────────────────────────────────────────────────────────────────
# Each check takes a repo root and exits non-zero when the pipeline wiring is broken.

# shellcheck disable=SC2016
CHECKS='
root = ARGV.fetch(1)
conductor = File.join(root, "agents", "review-pipeline-agent.md")

def frontmatter(path)
  match = File.read(path).match(/\A---\n(.*?)\n---\n/m) or abort "#{path}: no frontmatter"
  YAML.safe_load(match[1])
end

def list(value)
  Array(value).flat_map { |item| item.to_s.split(/,\s*/) }
end

def section(text, heading)
  text[/^#{Regexp.escape(heading)}.*?(?=^## |\z)/m] or abort "missing section #{heading}"
end

binding_agents = section(File.read(conductor), "## Dispatch binding").scan(/^- `([a-z-]+-agent)`/).flatten

case ARGV.fetch(0)
when "binding_agents_exist"
  abort "binding lists no agents" if binding_agents.empty?
  binding_agents.each do |name|
    path = File.join(root, "agents", "#{name}.md")
    abort "#{name}: no agent file" unless File.file?(path)
    abort "#{name}: frontmatter name differs" unless frontmatter(path)["name"] == name
  end
when "lens_reviewers_are_read_only_leaves"
  ARGV.drop(2).each do |name|
    config = frontmatter(File.join(root, "agents", "#{name}.md"))
    writers = list(config["tools"]) & %w[write edit subagent]
    abort "#{name}: can #{writers.join(", ")}" unless writers.empty?
    abort "#{name}: inherits skills" unless config["inheritSkills"] == false
    list(config["skills"]).each do |skill_name|
      abort "#{name}: missing skill #{skill_name}" unless File.file?(File.join(root, "skills", skill_name, "SKILL.md"))
    end
  end
when "lens_agents_list_their_skill"
  ARGV.drop(2).each do |name|
    skill_name = name.delete_suffix("-agent")
    abort "#{name}: does not list #{skill_name}" unless list(frontmatter(File.join(root, "agents", "#{name}.md"))["skills"]).include?(skill_name)
  end
when "rules_globs_resolve"
  globs = File.read(File.join(root, "skills", "mihai-rules-review", "SKILL.md")).scan(%r{~/\.ai/rules/([^\s`]+\.md)}).flatten.uniq
  abort "rules reviewer names no rule files" if globs.empty?
  globs.each do |glob|
    matches = Dir.glob(File.join(root, "rules", glob)).select { |path| File.file?(path) && !File.symlink?(path) }
    abort "#{glob} matches #{matches.size} rule files" unless matches.size == 1
  end
else
  abort "unknown check #{ARGV[0]}"
end
'

check() { ruby -ryaml -e "$CHECKS" "$@"; }

# ── Planting ──────────────────────────────────────────────────────────────────
# A planted copy of the repo with one wiring mistake must fail the matching check.

planted_copy() {
    local copy="$SANDBOX/copy"
    rm -rf "$copy"
    mkdir -p "$copy"
    cp -R "$REPO_ROOT/agents" "$REPO_ROOT/skills" "$REPO_ROOT/rules" "$copy/"
    printf '%s\n' "$copy"
}

planted_check_fails() {
    local mutation="$1" copy; shift
    copy="$(planted_copy)"
    "$mutation" "$copy" || return 1
    ! check "$1" "$copy" "${@:2}"
}

replace_in() {
    ruby -e 'path, from, to = ARGV; text = File.read(path); abort "#{from} not in #{path}" unless text.include?(from); File.write(path, text.sub(from, to))' "$@"
}

plant_missing_agent() { rm "$1/agents/mihai-rules-review-agent.md"; }
plant_writing_lens() { replace_in "$1/agents/mihai-pattern-review-agent.md" 'tools: read' 'tools: write, read'; }
plant_missing_lens_skill() { replace_in "$1/agents/mihai-rules-review-agent.md" 'skills: mihai-rules-review, mihai-code-review' 'skills: mihai-rules-review, no-such-skill'; }
plant_unskilled_lens() { replace_in "$1/agents/mihai-pattern-review-agent.md" 'mihai-pattern-review, ' ''; }
plant_dangling_rule() { rm "$1/rules/"*_testing.md; }
plant_ambiguous_rule() { cp "$1/rules/"*_cleanup.md "$1/rules/99_cleanup.md"; }

# ── Test 1: the dispatch binding points at real agents ────────────────────────

assert "every agent in the dispatch binding exists" check binding_agents_exist "$REPO_ROOT"
assert "planted missing agent file is rejected" planted_check_fails plant_missing_agent binding_agents_exist

# ── Test 2: lens reviewers are read-only leaves with resolvable skills ────────

assert "lens reviewers cannot write or delegate" check lens_reviewers_are_read_only_leaves "$REPO_ROOT" "${LENS_REVIEWERS[@]}"
assert "planted lens reviewer with write is rejected" planted_check_fails plant_writing_lens lens_reviewers_are_read_only_leaves "${LENS_REVIEWERS[@]}"
assert "planted lens reviewer with a missing skill is rejected" planted_check_fails plant_missing_lens_skill lens_reviewers_are_read_only_leaves "${LENS_REVIEWERS[@]}"
assert "each lens reviewer lists its own skill" check lens_agents_list_their_skill "$REPO_ROOT" "${LENS_REVIEWERS[@]}"
assert "planted lens reviewer without its own skill is rejected" planted_check_fails plant_unskilled_lens lens_agents_list_their_skill "${LENS_REVIEWERS[@]}"

# ── Test 3: the rules reviewer points at real rule files ──────────────────────

assert "each rule glob in the rules reviewer resolves to one rule file" check rules_globs_resolve "$REPO_ROOT"
assert "planted glob with no rule file is rejected" planted_check_fails plant_dangling_rule rules_globs_resolve
assert "planted glob matching two rule files is rejected" planted_check_fails plant_ambiguous_rule rules_globs_resolve

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo "Passed: $PASS  Failed: $FAIL"
[ "$FAIL" -eq 0 ]
