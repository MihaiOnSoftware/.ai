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
skill = File.join(root, "skills", "review-pipeline", "SKILL.md")
recipes = File.join(root, "skills", "review-pipeline", "references", "phase-dispatch.md")

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
recipe_blocks = File.read(recipes).split(/^## /).drop(1).to_h { |block| [block.lines.first.strip, block] }
phase1 = recipe_blocks.select { |title, _| title.start_with?("Phase 1") }
phase1_tags = phase1.values.map { |block| block[/-([a-z]+)-output\.md"/, 1] }

case ARGV.fetch(0)
when "binding_agents_exist"
  abort "binding lists no agents" if binding_agents.empty?
  binding_agents.each do |name|
    path = File.join(root, "agents", "#{name}.md")
    abort "#{name}: no agent file" unless File.file?(path)
    abort "#{name}: frontmatter name differs" unless frontmatter(path)["name"] == name
  end
when "binding_names_lens_reviewers"
  missing = ARGV.drop(2) - binding_agents
  abort "binding misses #{missing.join(", ")}" unless missing.empty?
when "recipes_match_binding"
  recipe_agents = File.read(recipes).scan(/agent: "([a-z-]+)"/).flatten
  abort "recipes #{recipe_agents.sort} != binding #{binding_agents.sort}" unless recipe_agents.sort == binding_agents.sort
when "phase1_recipes_are_async"
  abort "fewer than two Phase 1 recipes" if phase1.size < 2
  phase1.each { |title, block| abort "#{title}: not async" unless block.include?("async: true") }
when "phase1_outputs_are_merge_sources"
  abort "a Phase 1 recipe has no -<tag>-output.md path" if phase1_tags.include?(nil)
  abort "Phase 1 output tags collide" unless phase1_tags.uniq.size == phase1_tags.size
  sources = File.read(skill)[/\(source: ([^)]*)\)/, 1] or abort "merge format has no source list"
  missing = phase1_tags - sources.split(/[^a-z]+/)
  abort "merge sources miss #{missing.join(", ")}" unless missing.empty?
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
when "rules_globs_resolve"
  globs = File.read(File.join(root, "agents", "mihai-rules-review-agent.md")).scan(%r{~/\.ai/rules/([^\s`]+\.md)}).flatten.uniq
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
plant_unbound_lens() { replace_in "$1/agents/review-pipeline-agent.md" '`mihai-pattern-review-agent`' '`some-other-agent`'; }
plant_missing_recipe() { replace_in "$1/skills/review-pipeline/references/phase-dispatch.md" 'agent: "mihai-rules-review-agent"' 'agent: "unbound-agent"'; }
plant_sync_lens() { replace_in "$1/skills/review-pipeline/references/phase-dispatch.md" "$(printf 'agent: "mihai-pattern-review-agent",\n  async: true')" 'agent: "mihai-pattern-review-agent",'; }
plant_dropped_source() { replace_in "$1/skills/review-pipeline/SKILL.md" '| rules' ''; }
plant_writing_lens() { replace_in "$1/agents/mihai-pattern-review-agent.md" 'tools: read' 'tools: write, read'; }
plant_missing_lens_skill() { replace_in "$1/agents/mihai-rules-review-agent.md" 'skills: mihai-code-review' 'skills: no-such-skill'; }
plant_dangling_rule() { rm "$1/rules/"*_testing.md; }
plant_ambiguous_rule() { cp "$1/rules/"*_cleanup.md "$1/rules/99_cleanup.md"; }

# ── Test 1: the conductor dispatches the lens reviewers ───────────────────────

assert "every agent in the dispatch binding exists" check binding_agents_exist "$REPO_ROOT"
assert "the dispatch binding names both lens reviewers" check binding_names_lens_reviewers "$REPO_ROOT" "${LENS_REVIEWERS[@]}"
assert "every bound agent has exactly one dispatch recipe" check recipes_match_binding "$REPO_ROOT"
assert "planted missing agent file is rejected" planted_check_fails plant_missing_agent binding_agents_exist
assert "planted unbound lens reviewer is rejected" planted_check_fails plant_unbound_lens binding_names_lens_reviewers "${LENS_REVIEWERS[@]}"
assert "planted recipe for an unbound agent is rejected" planted_check_fails plant_missing_recipe recipes_match_binding

# ── Test 2: every Phase 1 reviewer runs in parallel and reaches the merge ─────

assert "every Phase 1 recipe is async" check phase1_recipes_are_async "$REPO_ROOT"
assert "every Phase 1 output tag is a merge source" check phase1_outputs_are_merge_sources "$REPO_ROOT"
assert "planted synchronous lens recipe is rejected" planted_check_fails plant_sync_lens phase1_recipes_are_async
assert "planted merge format without the rules source is rejected" planted_check_fails plant_dropped_source phase1_outputs_are_merge_sources

# ── Test 3: lens reviewers are read-only leaves with resolvable skills ────────

assert "lens reviewers cannot write or delegate" check lens_reviewers_are_read_only_leaves "$REPO_ROOT" "${LENS_REVIEWERS[@]}"
assert "planted lens reviewer with write is rejected" planted_check_fails plant_writing_lens lens_reviewers_are_read_only_leaves "${LENS_REVIEWERS[@]}"
assert "planted lens reviewer with a missing skill is rejected" planted_check_fails plant_missing_lens_skill lens_reviewers_are_read_only_leaves "${LENS_REVIEWERS[@]}"

# ── Test 4: the rules reviewer points at real rule files ──────────────────────

assert "each rule glob in the rules reviewer resolves to one rule file" check rules_globs_resolve "$REPO_ROOT"
assert "planted glob with no rule file is rejected" planted_check_fails plant_dangling_rule rules_globs_resolve
assert "planted glob matching two rule files is rejected" planted_check_fails plant_ambiguous_rule rules_globs_resolve

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo "Passed: $PASS  Failed: $FAIL"
[ "$FAIL" -eq 0 ]
