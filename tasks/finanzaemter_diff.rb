# frozen_string_literal: true

# Summarises what changed between the committed Finanzamt table and the
# regenerated one, so a refresh PR is reviewable without reading 1700 lines of
# YAML. Reads the old copy from git and the new one from the working tree.
#
#   ruby tasks/finanzaemter_diff.rb [git-ref]

require 'yaml'
require 'open3'

DATA_PATH = 'lib/steuer/data/finanzaemter.yml'
ref = ARGV[0] || 'HEAD'

def load_table(yaml)
  parsed = YAML.safe_load(yaml) || {}
  [parsed['revision'], parsed['finanzaemter'] || {}]
end

previous_yaml, status = Open3.capture2('git', 'show', "#{ref}:#{DATA_PATH}")
old_revision, old_rows = status.success? ? load_table(previous_yaml) : [nil, {}]
new_revision, new_rows = load_table(File.read(DATA_PATH))

added = new_rows.keys - old_rows.keys
removed = old_rows.keys - new_rows.keys
renamed = (old_rows.keys & new_rows.keys).reject do |code|
  old_rows[code]['name'] == new_rows[code]['name']
end

lines = []
lines << "GemFA revision `#{old_revision || 'n/a'}` → `#{new_revision}`."
lines << ''
lines << "**#{new_rows.size} offices** " \
  "(#{added.size} added, #{removed.size} removed, #{renamed.size} renamed)."

unless added.empty?
  lines << ''
  lines << '### Added'
  added.sort.each { |code| lines << "- `#{code}` #{new_rows[code]['name']}" }
end

unless removed.empty?
  lines << ''
  lines << '### Removed'
  removed.sort.each { |code| lines << "- `#{code}` #{old_rows[code]['name']}" }
end

unless renamed.empty?
  lines << ''
  lines << '### Renamed'
  renamed.sort.each do |code|
    lines << "- `#{code}` #{old_rows[code]['name']} → #{new_rows[code]['name']}"
  end
end

if added.empty? && removed.empty? && renamed.empty?
  lines << ''
  lines << 'Only the revision date changed; no office entries differ.'
end

puts lines.join("\n")
