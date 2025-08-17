# frozen_string_literal: true

require_relative 'state_mapping'

module Steuer
  class Steuernummer
    attr_reader :original_input, :state_code

    def initialize(tax_number, state: nil)
      @original_input = tax_number.to_s.strip
      @state_code = normalize_state_code(state) || auto_detect_state

      validate_tax_number!
    end

    def valid?
      return false if @original_input.empty?
      return false unless format_type
      return false unless @state_code

      case format_type
      when :standard
        validate_standard_format
      when :federal_12
        validate_federal_12_format
      when :federal_13
        validate_federal_13_format
      else
        false
      end
    end

    def to_federal_12
      return unless valid?

      case format_type
      when :standard
        convert_standard_to_federal_12
      when :federal_12
        normalized_input
      when :federal_13
        convert_federal_13_to_federal_12
      end
    end

    def to_federal_13
      return unless valid?

      case format_type
      when :standard
        convert_standard_to_federal_13
      when :federal_12
        convert_federal_12_to_federal_13
      when :federal_13
        normalized_input
      end
    end

    def to_standard
      return unless valid?

      case format_type
      when :standard
        @original_input
      when :federal_12
        convert_federal_12_to_standard
      when :federal_13
        convert_federal_13_to_standard
      end
    end

    def state
      return unless @state_code

      StateMapping::STATES[@state_code][:name]
    end

    def format_type
      @format_type ||= if normalized_input.include?('/')
        :standard
      elsif normalized_input.length == 12 && normalized_input.match?(/^\d{12}$/)
        :federal_12
      elsif normalized_input.length == 13 && normalized_input.match?(/^\d{13}$/)
        :federal_13
      end

      @format_type
    end

    private

    def normalized_input
      @normalized_input_input ||= if @original_input.include?('/') || @original_input.include?('-')
        @original_input.gsub(%r{[^0-9/\-]}, '').tr('-', '/')
      else
        @original_input.gsub(/[^0-9]/, '')
      end
      @normalized_input_input
    end

    def validate_tax_number!
      unless format_type
        raise InvalidTaxNumberError, "Invalid tax number format: #{@original_input}"
      end

      # Auto-detect state if not provided
      if @state_code.nil?
        raise UnsupportedStateError,
          "Cannot determine state from tax number #{@original_input}. Please provide state parameter."
      end

      unless StateMapping::STATES.key?(@state_code)
        raise UnsupportedStateError, "Unsupported state: #{@state_code}"
      end

      # Validate that the tax number matches the state's expected pattern
      unless valid_for_state?
        raise InvalidTaxNumberError, "Tax number #{@original_input} is not valid for state #{@state_code}"
      end
    end

    def normalize_state_code(state)
      return if state.nil? || state.to_s.strip.empty?

      state_str = state.to_s.strip.upcase

      return state_str if StateMapping::STATES.key?(state_str)

      StateMapping::STATES.find { |_code, config| config[:name].upcase == state_str }&.first || state_str
    end

    def auto_detect_state
      case format_type
      when :standard
        StateMapping.find_state_by_standard_format(normalized_input)
      when :federal_12
        # Only auto-detect if prefix is unambiguous
        detected = StateMapping.find_state_by_federal_12(normalized_input)
        return detected if detected && unambiguous_federal_prefix?(detected, normalized_input, :federal_12)

        nil
      when :federal_13
        # Only auto-detect if prefix is unambiguous
        detected = StateMapping.find_state_by_federal_13(normalized_input)
        return detected if detected && unambiguous_federal_prefix?(detected, normalized_input, :federal_13)

        nil
      end
    end

    def unambiguous_federal_prefix?(detected_state, tax_number, format_type)
      prefix_key = format_type == :federal_12 ? :federal_12_prefix : :federal_13_prefix
      detected_prefix = StateMapping::STATES[detected_state][prefix_key]

      # Count how many states share this prefix
      matching_states = StateMapping::STATES.count do |_, config|
        config[prefix_key] == detected_prefix
      end

      # Only unambiguous if exactly one state has this prefix
      matching_states == 1
    end

    def valid_for_state?
      return false unless @state_code && StateMapping::STATES.key?(@state_code)

      case format_type
      when :standard
        validate_standard_format
      when :federal_12
        validate_federal_12_format
      when :federal_13
        validate_federal_13_format
      else
        false
      end
    end

    def validate_standard_format
      config = StateMapping::STATES[@state_code]
      normalized_input.match?(config[:standard_pattern])
    end

    def validate_federal_12_format
      return false unless normalized_input.length == 12
      return false unless normalized_input.match?(/^\d{12}$/)

      config = StateMapping::STATES[@state_code]
      normalized_input.start_with?(config[:federal_12_prefix])
    end

    def validate_federal_13_format
      return false unless normalized_input.length == 13
      return false unless normalized_input.match?(/^\d{13}$/)

      config = StateMapping::STATES[@state_code]
      normalized_input.start_with?(config[:federal_13_prefix])
    end

    def convert_standard_to_federal_12
      config = StateMapping::STATES[@state_code]

      match = normalized_input.match(config[:standard_pattern])
      return unless match

      parts = match.captures

      case @state_code
      when 'NW' # Nordrhein-Westfalen has different structure (FFF/BBBB/UUUP)
        fff, bbbb, uuup = parts
        "#{config[:federal_12_prefix]}#{fff}#{bbbb}#{uuup}"
      when 'HE' # Hessen (has leading zero in standard format)
        if parts.length == 3
          ff_or_fff, bbb, uuuup = parts
          # Remove leading zero from Finanzamt code for federal format
          finanzamt = ff_or_fff.sub(/^0/, '')
          "#{config[:federal_12_prefix]}#{finanzamt}#{bbb}#{uuuup}"
        end
      else
        if parts.length == 3
          ff_or_fff, bbb, uuuup = parts
          "#{config[:federal_12_prefix]}#{ff_or_fff}#{bbb}#{uuuup}"
        end
      end
    end

    def convert_standard_to_federal_13
      federal_12 = convert_standard_to_federal_12
      return unless federal_12

      config = StateMapping::STATES[@state_code]
      insert_position = config[:federal_13_zero_position]

      result = federal_12.dup
      result.insert(insert_position, '0')
      result
    end

    def convert_federal_12_to_federal_13
      config = StateMapping::STATES[@state_code]
      insert_position = config[:federal_13_zero_position]

      result = normalized_input.dup
      result.insert(insert_position, '0')
      result
    end

    def convert_federal_13_to_federal_12
      config = StateMapping::STATES[@state_code]
      remove_position = config[:federal_13_zero_position]

      result = normalized_input.dup
      result.slice!(remove_position)
      result
    end

    def convert_federal_12_to_standard
      federal_12_to_standard_format(normalized_input)
    end

    def convert_federal_13_to_standard
      federal_12 = convert_federal_13_to_federal_12
      return unless federal_12

      federal_12_to_standard_format(federal_12)
    end

    def federal_12_to_standard_format(federal_12_string)
      config = StateMapping::STATES[@state_code]
      prefix = config[:federal_12_prefix]

      # Remove the prefix
      without_prefix = federal_12_string[prefix.length..-1]

      case @state_code
      when 'NW' # Nordrhein-Westfalen (FFF/BBBB/UUUP)
        fff = without_prefix[0, 3]
        bbbb = without_prefix[3, 4]
        uuup = without_prefix[7, 4]
        "#{fff}/#{bbbb}/#{uuup}"
      when 'HE' # Hessen (has leading 0 in standard format)
        ff = without_prefix[0, 2]
        bbb = without_prefix[2, 3]
        uuuup = without_prefix[5, 5]
        "0#{ff}/#{bbb}/#{uuuup}"
      else
        if prefix.length == 1 # Single digit prefix states
          fff = without_prefix[0, 3]
          bbb = without_prefix[3, 3]
          uuuup = without_prefix[6, 5]
          "#{fff}/#{bbb}/#{uuuup}"
        else # Two digit prefix states
          ff = without_prefix[0, 2]
          bbb = without_prefix[2, 3]
          uuuup = without_prefix[5, 5]
          "#{ff}/#{bbb}/#{uuuup}"
        end
      end
    end

    alias_method :to_elster, :to_federal_13
  end
end
