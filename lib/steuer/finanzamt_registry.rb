# frozen_string_literal: true

require 'yaml'

module Steuer
  # Lookup of Bundesfinanzamtsnummer (BUFA-Nr, the four-digit prefix of the
  # federal-13 form) to the office's name, backed by the BZSt BUFA-Tabelle
  # bundled in data/finanzaemter.yml.
  #
  # Unlike the structural data in StateMapping, these names go stale: offices
  # merge and get renamed several times a year. Lookups therefore return nil
  # rather than raising, so a number issued after the bundled table's revision
  # still converts -- it just has no name yet.
  module FinanzamtRegistry
    DATA_PATH = File.expand_path('data/finanzaemter.yml', __dir__)

    class << self
      def name_for(code)
        entries[code.to_s]&.fetch(:name, nil)
      end

      def state_for(code)
        entries[code.to_s]&.fetch(:state, nil)
      end

      def known?(code)
        entries.key?(code.to_s)
      end

      def revision
        data[:revision]
      end

      def entries
        @entries ||= data[:finanzaemter].to_h do |code, attrs|
          [code.to_s, { name: attrs['name'], state: attrs['state'] }.freeze]
        end.freeze
      end

      private

      def data
        @data ||= begin
          loaded = YAML.safe_load_file(DATA_PATH)
          { revision: loaded['revision'], finanzaemter: loaded['finanzaemter'] || {} }
        end
      end
    end
  end
end
