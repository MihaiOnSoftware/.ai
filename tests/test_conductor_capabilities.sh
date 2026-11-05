#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

ruby -ryaml - "$REPO_ROOT" <<'RUBY'
root = ARGV.fetch(0)
conductors = %w[solve-this-problem-agent tdd-slice-agent review-pipeline-agent adversarial-review-loop-agent]
required_tools = %w[subagent bg_wait contact_supervisor subagent_supervisor]
failures = []

agents = Dir.glob(File.join(root, 'agents', '*.md')).to_h do |file|
  frontmatter = File.read(file).match(/\A---\n(.*?)\n---\n/m)
  config = YAML.safe_load(frontmatter[1])
  [config.fetch('name'), config]
end

def list(value)
  Array(value).flat_map { |item| item.split(/,\s*/) }
end

conductors.each do |name|
  config = agents.fetch(name)
  missing = required_tools - list(config['tools'])
  failures << "#{name}: missing tools #{missing.join(', ')}" unless missing.empty?
end

designer = agents.fetch('explore-and-design-agent')
failures << 'design agent cannot launch its required fresh-context reviews' unless designer['allowNestedSubagents'] == true
failures << 'design agent lost its default research tools' if designer.key?('tools')
expected_reviewers = %w[adversarial-review-agent investigator-agent]
failures << 'design review/probe fanout is not scoped to its specialists' unless list(designer['allowedAgents']).sort == expected_reviewers.sort

(conductors + ['explore-and-design-agent']).each do |name|
  skills = list(agents.fetch(name)['skills'])
  failures << "#{name}: missing coordinating-children skill" unless skills.include?('coordinating-children')
end

skill = File.join(root, 'skills', 'coordinating-children', 'SKILL.md')
failures << 'shared coordinating-children skill is missing' unless File.file?(skill)
abort failures.join("\n") unless failures.empty?
puts 'Four conductors and the design review/probe boundary have their required coordination grants.'
RUBY
