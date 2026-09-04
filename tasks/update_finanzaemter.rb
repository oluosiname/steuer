# frozen_string_literal: true

# Regenerates lib/steuer/data/finanzaemter.yml from the BZSt GemFA export.
# BZSt republishes GemFA on the 1st and 15th of each month, so re-run this
# before cutting a release and commit the resulting diff.
#
#   rake update_finanzaemter

require 'net/http'
require 'uri'
require 'tmpdir'
require 'rexml/document'
require 'yaml'

require_relative '../lib/steuer/state_mapping'

GEMFA_URL = 'https://www.bzst.de/SharedDocs/Downloads/DE/GemFA/gemfa_xml_export_datei.zip?__blob=publicationFile&v=1'
OUTPUT = File.expand_path('../lib/steuer/data/finanzaemter.yml', __dir__)

# GemFA records no Bundesland. The BUFA-Nr's leading digits are the same
# federal prefix StateMapping keys states by, so the longest unambiguous match
# supplies it; shared prefixes ('3' and '4') deliberately yield no state.
def state_for(bufa, prefixes)
  2.downto(1) do |length|
    candidates = prefixes[bufa[0, length]]
    return candidates.first if candidates && candidates.length == 1
  end
  nil
end

def prefixes
  Steuer::StateMapping::STATES
    .group_by { |_code, config| config[:federal_13_prefix] }
    .transform_values { |pairs| pairs.map(&:first) }
end

def download(dir)
  archive = File.join(dir, 'gemfa.zip')
  uri = URI(GEMFA_URL)

  Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
    response = http.get(uri.request_uri)
    raise "GemFA download failed: HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    File.binwrite(archive, response.body)
  end

  system('unzip', '-o', '-q', archive, '-d', dir) || raise('Could not unzip the GemFA export')
  Dir[File.join(dir, 'GemFA_Export_*.xml')].max_by { |path| File.basename(path) } ||
    raise('GemFA export did not contain a GemFA_Export_*.xml file')
end

def build(xml_path)
  document = REXML::Document.new(File.read(xml_path))
  lookup = prefixes

  rows = {}
  REXML::XPath.each(document, "//*[local-name()='Finanzamt']") do |element|
    bufa = element.attributes['BuFaNr']
    next if bufa.nil?

    entry = { 'name' => element.attributes['Name'] }
    state = state_for(bufa, lookup)
    entry['state'] = state if state
    rows[bufa] = entry
  end

  raise 'GemFA export yielded no Finanzamt entries' if rows.empty?

  rows.sort.to_h
end

Dir.mktmpdir do |dir|
  xml_path = download(dir)
  revision = File.basename(xml_path)[/(\d{4})(\d{2})(\d{2})/]
  revision = "#{Regexp.last_match(1)}-#{Regexp.last_match(2)}-#{Regexp.last_match(3)}"
  rows = build(xml_path)

  File.write(OUTPUT, YAML.dump(
    'revision' => revision,
    'source' => 'BZSt GemFA (Gesamtverzeichnis der Finanzaemter)',
    'finanzaemter' => rows,
  ))

  puts "Wrote #{rows.size} Finanzämter (GemFA revision #{revision}) to #{OUTPUT}"
end
