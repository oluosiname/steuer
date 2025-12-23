# frozen_string_literal: true

module Steuer
  module StateMapping
    # Mapping from state codes to their configuration
    # Based on https://de.wikipedia.org/wiki/Steuernummer#Deutschland
    STATES = {
      'BW' => {
        name: 'Baden-Württemberg',
        standard_pattern: %r{^(\d{2})/(\d{3})/(\d{5})$},
        federal_12_prefix: '28',
        federal_13_prefix: '28',
        federal_13_zero_position: 4, # Insert 0 at position 4 (after FF)
      },
      'BY' => {
        name: 'Bayern',
        standard_pattern: %r{^(\d{3})/(\d{3})/(\d{5})$},
        federal_12_prefix: '9',
        federal_13_prefix: '9',
        federal_13_zero_position: 4, # Insert 0 at position 4 (after FFF)
      },
      'BE' => {
        name: 'Berlin',
        standard_pattern: %r{^(\d{2})/(\d{3})/(\d{5})$},
        federal_12_prefix: '11',
        federal_13_prefix: '11',
        federal_13_zero_position: 4, # Insert 0 at position 4 (after FF)
      },
      'BB' => {
        name: 'Brandenburg',
        standard_pattern: %r{^(\d{3})/(\d{3})/(\d{5})$},
        federal_12_prefix: '3',
        federal_13_prefix: '3',
        federal_13_zero_position: 4, # Insert 0 at position 4 (after FFF)
      },
      'HB' => {
        name: 'Bremen',
        standard_pattern: %r{^(\d{2})/(\d{3})/(\d{5})$},
        federal_12_prefix: '24',
        federal_13_prefix: '24',
        federal_13_zero_position: 4, # Insert 0 at position 4 (after FF)
      },
      'HH' => {
        name: 'Hamburg',
        standard_pattern: %r{^(\d{2})/(\d{3})/(\d{5})$},
        federal_12_prefix: '22',
        federal_13_prefix: '22',
        federal_13_zero_position: 4, # Insert 0 at position 4 (after FF)
      },
      'HE' => {
        name: 'Hessen',
        standard_pattern: %r{^0(1[3-9])/(\d{3})/(\d{5})$}, # More specific: 013-019 range, capture 13-19
        federal_12_prefix: '26',
        federal_13_prefix: '26',
        federal_13_zero_position: 4, # Insert 0 at position 4 (after FF)
      },
      'MV' => {
        name: 'Mecklenburg-Vorpommern',
        standard_pattern: %r{^(\d{3})/(\d{3})/(\d{5})$},
        federal_12_prefix: '4',
        federal_13_prefix: '4',
        federal_13_zero_position: 4, # Insert 0 at position 4 (after FFF)
      },
      'NI' => {
        name: 'Niedersachsen',
        standard_pattern: %r{^(\d{2})/(\d{3})/(\d{5})$},
        federal_12_prefix: '23',
        federal_13_prefix: '23',
        federal_13_zero_position: 4, # Insert 0 at position 4 (after FF)
      },
      'NW' => {
        name: 'Nordrhein-Westfalen',
        standard_pattern: %r{^(\d{3})/(\d{4})/(\d{4})$},
        federal_12_prefix: '5',
        federal_13_prefix: '5',
        federal_13_zero_position: 4, # Insert 0 at position 4 (after FFF)
      },
      'RP' => {
        name: 'Rheinland-Pfalz',
        standard_pattern: %r{^(\d{2})/(\d{3})/(\d{5})$},
        federal_12_prefix: '27',
        federal_13_prefix: '27',
        federal_13_zero_position: 4, # Insert 0 at position 4 (after FF)
      },
      'SL' => {
        name: 'Saarland',
        standard_pattern: %r{^(01[0-2])/(\d{3})/(\d{5})$}, # Specific to 010-012 for Saarland
        federal_12_prefix: '1',
        federal_13_prefix: '1',
        federal_13_zero_position: 4, # Insert 0 at position 4 (after FFF)
      },
      'SN' => {
        name: 'Sachsen',
        standard_pattern: %r{^(\d{3})/(\d{3})/(\d{5})$},
        federal_12_prefix: '3',
        federal_13_prefix: '3',
        federal_13_zero_position: 4, # Insert 0 at position 4 (after FFF)
      },
      'ST' => {
        name: 'Sachsen-Anhalt',
        standard_pattern: %r{^(\d{3})/(\d{3})/(\d{5})$},
        federal_12_prefix: '3',
        federal_13_prefix: '3',
        federal_13_zero_position: 4, # Insert 0 at position 4 (after FFF)
      },
      'SH' => {
        name: 'Schleswig-Holstein',
        standard_pattern: %r{^(\d{2})/(\d{3})/(\d{5})$},
        federal_12_prefix: '21',
        federal_13_prefix: '21',
        federal_13_zero_position: 4, # Insert 0 at position 4 (after FF)
      },
      'TH' => {
        name: 'Thüringen',
        standard_pattern: %r{^(\d{3})/(\d{3})/(\d{5})$},
        federal_12_prefix: '4',
        federal_13_prefix: '4',
        federal_13_zero_position: 4, # Insert 0 at position 4 (after FFF)
      },
    }.freeze
    class << self
      def find_state_by_standard_format(tax_number)
        # Try more specific patterns first to avoid conflicts with general patterns
        # Priority: character classes with ranges > specific digit patterns > general digit patterns
        sorted_states = STATES.sort_by do |_, config|
          pattern_str = config[:standard_pattern].source
          if pattern_str.include?('[') # Character classes like [0-2] or [3-9]
            0
          elsif pattern_str.include?('0(') || pattern_str.start_with?('^0') # Patterns starting with specific digit
            1
          else # General patterns like (\d{3})
            2
          end
        end

        # Find all states that match the pattern
        matching_states = sorted_states.select do |_code, config|
          tax_number.match?(config[:standard_pattern])
        end

        # If only one state matches, return it (unambiguous)
        return matching_states.first[0] if matching_states.length == 1

        # If multiple states match (ambiguous), return nil
        # This will trigger the error requiring explicit state parameter
        # (same behavior as ambiguous federal prefixes like '3' or '4')
        return if matching_states.length > 1

        # No matches
        nil
      end

      def find_state_by_federal_12(tax_number)
        return unless tax_number.length == 12

        # Try exact prefix matches, longest first to avoid conflicts
        # e.g., '28' should match before '2', '11' before '1'
        sorted_states = STATES.sort_by { |_, config| -config[:federal_12_prefix].length }

        sorted_states.each do |code, config|
          prefix = config[:federal_12_prefix]

          # Check if tax number starts with this exact prefix
          next unless tax_number.start_with?(prefix)

          # For single digit prefixes, ensure we don't match longer numbers
          if prefix.length == 1
            # For single digit, check that the next digit doesn't make it a longer prefix
            next_char = tax_number[prefix.length]
            return nil if next_char.nil? # Invalid tax number

            # Skip if this would create a longer prefix that exists
            longer_prefix = prefix + next_char
            has_longer_prefix = STATES.any? { |_, c| c[:federal_12_prefix] == longer_prefix }
            next if has_longer_prefix

            # Additional validation: reject obviously invalid combinations
            # For prefix '9' (Bayern), '99' is not a valid federal tax number start
            if prefix == '9' && next_char == '9'
              return nil
            end
          end

          return code
        end
        nil
      end

      def find_state_by_federal_13(tax_number)
        return unless tax_number.length == 13

        # Try exact prefix matches, longest first to avoid conflicts
        sorted_states = STATES.sort_by { |_, config| -config[:federal_13_prefix].length }

        sorted_states.each do |code, config|
          prefix = config[:federal_13_prefix]

          # Check if tax number starts with this exact prefix
          next unless tax_number.start_with?(prefix)

          # For single digit prefixes, ensure we don't match longer numbers
          if prefix.length == 1
            # For single digit, check that the next digit doesn't make it a longer prefix
            next_char = tax_number[prefix.length]
            return nil if next_char.nil? # Invalid tax number

            # Skip if this would create a longer prefix that exists
            longer_prefix = prefix + next_char
            has_longer_prefix = STATES.any? { |_, c| c[:federal_13_prefix] == longer_prefix }
            next if has_longer_prefix
          end

          return code
        end
        nil
      end
    end
  end
end
