#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

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
# Each check takes a repo root and exits non-zero when the skill's wiring is broken.

# shellcheck disable=SC2016
CHECKS='
root = ARGV.fetch(1)
skill_dir = File.join(root, "skills", "monitor-gh-pr")
skill = File.read(File.join(skill_dir, "SKILL.md"))
reviewer_script = File.read(File.join(skill_dir, "scripts", "monitor-gh-pr-review.sh"))
rereview = File.read(File.join(skill_dir, "references", "rereview.md")) rescue ""

def section(text, heading)
  text[/^#{Regexp.escape(heading)}.*?(?=^## |\z)/m] or abort "missing section #{heading}"
end

case ARGV.fetch(0)
when "reviewer_options_are_documented"
  usage = reviewer_script[/^Usage: .*$/] or abort "script has no usage line"
  options = usage.scan(/--[a-z-]+/).uniq
  inputs = section(skill, "## Inputs")
  missing = options.reject { |option| inputs.match?(/^\| `#{Regexp.escape(option)}[ `]/) }
  abort "Inputs misses #{missing.join(", ")}" unless missing.empty?
when "skill_links_resolve"
  links = skill.scan(/\]\(([^)#:]+)\)/).flatten
  abort "SKILL.md links nothing" if links.empty?
  links.each { |link| abort "#{link} does not exist" unless File.exist?(File.join(skill_dir, link)) }
when "rereview_modes_match_script"
  modes = reviewer_script[/^\s*([a-z|-]+)\) REREVIEW=/, 1] or abort "script accepts no modes"
  modes.split("|").each { |mode| abort "rereview.md misses --rereview #{mode}" unless rereview.include?("`--rereview #{mode}`") }
when "documented_approval_is_bodyless_and_pinned"
  commands = rereview.lines.grep(/event=APPROVE/)
  abort "rereview.md documents no approve command" if commands.empty?
  commands.each do |line|
    abort "approve is not pinned to a commit: #{line}" unless line.include?("commit_id=")
    abort "approve carries a body or comments: #{line}" if line =~ /body|comments/
  end
when "conductor_skills_resolve"
  conductor = File.read(File.join(root, "agents", "review-pipeline-agent.md"))
  skills = conductor[/^skills: (.*)$/, 1] or abort "conductor lists no skills"
  abort "conductor does not list monitor-gh-pr" unless skills.split(/,\s*/).include?("monitor-gh-pr")
  skills.split(/,\s*/).each do |name|
    abort "#{name}: no SKILL.md" unless File.file?(File.join(root, "skills", name, "SKILL.md"))
  end
else
  abort "unknown check #{ARGV[0]}"
end
'

check() { ruby -e "$CHECKS" "$@"; }

# ── Planting ──────────────────────────────────────────────────────────────────
# A planted copy of the repo with one wiring mistake must fail the matching check.

planted_copy() {
    local copy="$SANDBOX/copy"
    rm -rf "$copy"
    mkdir -p "$copy"
    cp -R "$REPO_ROOT/agents" "$REPO_ROOT/skills" "$REPO_ROOT/tests" "$copy/"
    printf '%s\n' "$copy"
}

planted_check_fails() {
    local mutation="$1" copy; shift
    copy="$(planted_copy)"
    "$mutation" "$copy" || return 1
    ! check "$1" "$copy"
}

replace_in() {
    ruby -e 'path, from, to = ARGV; text = File.read(path); abort "#{from} not in #{path}" unless text.include?(from); File.write(path, text.sub(from, to))' "$@"
}

SKILL_MD=skills/monitor-gh-pr/SKILL.md
REREVIEW_MD=skills/monitor-gh-pr/references/rereview.md

# shellcheck disable=SC2016  # the backticks are literal markdown
plant_undocumented_option() { replace_in "$1/$SKILL_MD" '| `--rereview MODE`' '| `--mode MODE`'; }
plant_missing_reference() { rm "$1/$REREVIEW_MD"; }
# shellcheck disable=SC2016
plant_undocumented_mode() { replace_in "$1/$REREVIEW_MD" '`--rereview auto-approve`' '`--rereview auto`'; }
plant_approval_with_body() { replace_in "$1/$REREVIEW_MD" '-f event=APPROVE' '-f event=APPROVE -f body=LGTM'; }
plant_unpinned_approval() { replace_in "$1/$REREVIEW_MD" ' -f commit_id=<sha>' ''; }
plant_unlisted_skill() { replace_in "$1/agents/review-pipeline-agent.md" ', monitor-gh-pr' ''; }

# ── Test 1: every reviewer option and mode is documented ──────────────────────

assert "every reviewer script option is in the Inputs table" check reviewer_options_are_documented "$REPO_ROOT"
assert "every --rereview mode the script accepts is in rereview.md" check rereview_modes_match_script "$REPO_ROOT"
assert "planted undocumented option is rejected" planted_check_fails plant_undocumented_option reviewer_options_are_documented
assert "planted renamed mode is rejected" planted_check_fails plant_undocumented_mode rereview_modes_match_script

# ── Test 2: the skill's references resolve ────────────────────────────────────

assert "every relative link in SKILL.md resolves" check skill_links_resolve "$REPO_ROOT"
assert "planted missing rereview.md is rejected" planted_check_fails plant_missing_reference skill_links_resolve

# ── Test 3: the documented approval is the empty-body one ─────────────────────

assert "the documented approval has no body or comments and is pinned" check documented_approval_is_bodyless_and_pinned "$REPO_ROOT"
assert "planted approval with a body is rejected" planted_check_fails plant_approval_with_body documented_approval_is_bodyless_and_pinned
assert "planted unpinned approval is rejected" planted_check_fails plant_unpinned_approval documented_approval_is_bodyless_and_pinned

# ── Test 4: the review-pipeline conductor can load the skill ──────────────────

assert "the conductor lists monitor-gh-pr and its skills resolve" check conductor_skills_resolve "$REPO_ROOT"
assert "planted conductor without monitor-gh-pr is rejected" planted_check_fails plant_unlisted_skill conductor_skills_resolve

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo "Passed: $PASS  Failed: $FAIL"
[ "$FAIL" -eq 0 ]
