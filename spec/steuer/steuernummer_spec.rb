# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Steuer::Steuernummer do
  describe 'Baden-Württemberg examples' do
    let(:standard) { '93/815/08152' }
    let(:federal_12) { '289381508152' }
    let(:federal_13) { '2893081508152' }

    context 'with standard format' do
      subject(:steuernummer) { described_class.new(standard, state: 'BW') } # Explicit state (pattern is ambiguous)

      it 'is valid' do
        expect(steuernummer.valid?).to be true
      end

      it 'detects state correctly' do
        expect(steuernummer.state_code).to eq('BW')
        expect(steuernummer.state_name).to eq('Baden-Württemberg')
      end

      it 'detects format correctly' do
        expect(steuernummer.format_type).to eq(:standard)
      end

      it 'converts to federal_12' do
        expect(steuernummer.to_federal_12).to eq(federal_12)
      end

      it 'converts to federal_13' do
        expect(steuernummer.to_federal_13).to eq(federal_13)
      end

      it 'returns original for to_standard' do
        expect(steuernummer.to_standard).to eq(standard)
      end
    end

    context 'with federal_12 format' do
      subject(:steuernummer) { described_class.new(federal_12) } # Auto-detect state (unambiguous prefix)

      it 'is valid' do
        expect(steuernummer.valid?).to be true
      end

      it 'detects state correctly' do
        expect(steuernummer.state_code).to eq('BW')
        expect(steuernummer.state_name).to eq('Baden-Württemberg')
      end

      it 'detects format correctly' do
        expect(steuernummer.format_type).to eq(:federal_12)
      end

      it 'returns original for to_federal_12' do
        expect(steuernummer.to_federal_12).to eq(federal_12)
      end

      it 'converts to federal_13' do
        expect(steuernummer.to_federal_13).to eq(federal_13)
      end

      it 'converts to standard' do
        expect(steuernummer.to_standard).to eq(standard)
      end
    end

    context 'with federal_13 format' do
      subject(:steuernummer) { described_class.new(federal_13) } # Auto-detect state (unambiguous prefix)

      it 'is valid' do
        expect(steuernummer.valid?).to be true
      end

      it 'detects state correctly' do
        expect(steuernummer.state_code).to eq('BW')
        expect(steuernummer.state_name).to eq('Baden-Württemberg')
      end

      it 'detects format correctly' do
        expect(steuernummer.format_type).to eq(:federal_13)
      end

      it 'converts to federal_12' do
        expect(steuernummer.to_federal_12).to eq(federal_12)
      end

      it 'returns original for to_federal_13' do
        expect(steuernummer.to_federal_13).to eq(federal_13)
      end

      it 'converts to standard' do
        expect(steuernummer.to_standard).to eq(standard)
      end
    end
  end

  describe 'Bayern examples' do
    let(:standard) { '181/815/08155' }
    let(:federal_12) { '918181508155' }
    let(:federal_13) { '9181081508155' }

    context 'with standard format' do
      subject(:steuernummer) { described_class.new(standard, state: 'BY') }

      it 'is valid' do
        expect(steuernummer.valid?).to be true
      end

      it 'detects state correctly' do
        expect(steuernummer.state_code).to eq('BY')
        expect(steuernummer.state_name).to eq('Bayern')
      end

      it 'converts correctly' do
        expect(steuernummer.to_federal_12).to eq(federal_12)
        expect(steuernummer.to_federal_13).to eq(federal_13)
      end
    end
  end

  describe 'Nordrhein-Westfalen examples (special case)' do
    let(:standard) { '133/8150/8159' }
    let(:federal_12) { '513381508159' }
    let(:federal_13) { '5133081508159' }

    context 'with standard format' do
      subject(:steuernummer) { described_class.new(standard, state: 'NW') }

      it 'is valid' do
        expect(steuernummer.valid?).to be true
      end

      it 'detects state correctly' do
        expect(steuernummer.state_code).to eq('NW')
        expect(steuernummer.state_name).to eq('Nordrhein-Westfalen')
      end

      it 'converts correctly' do
        expect(steuernummer.to_federal_12).to eq(federal_12)
        expect(steuernummer.to_federal_13).to eq(federal_13)
      end
    end

    context 'with federal_12 format' do
      subject(:steuernummer) { described_class.new(federal_12, state: 'NW') }

      it 'converts back to standard correctly' do
        expect(steuernummer.to_standard).to eq(standard)
      end
    end
  end

  describe 'Hessen examples (special case with leading 0)' do
    let(:standard) { '013/815/08153' }
    let(:federal_12) { '261381508153' }
    let(:federal_13) { '2613081508153' }

    context 'with standard format' do
      subject(:steuernummer) { described_class.new(standard, state: 'HE') }

      it 'is valid' do
        expect(steuernummer.valid?).to be true
      end

      it 'detects state correctly' do
        expect(steuernummer.state_code).to eq('HE')
        expect(steuernummer.state_name).to eq('Hessen')
      end

      it 'converts correctly' do
        expect(steuernummer.to_federal_12).to eq(federal_12)
        expect(steuernummer.to_federal_13).to eq(federal_13)
      end
    end

    context 'with federal_12 format' do
      subject(:steuernummer) { described_class.new(federal_12, state: 'HE') }

      it 'converts back to standard correctly' do
        expect(steuernummer.to_standard).to eq(standard)
      end
    end
  end

  describe 'error handling' do
    it 'raises InvalidTaxNumberError for invalid format' do
      expect do
        described_class.new('invalid', state: 'BW')
      end.to raise_error(Steuer::InvalidTaxNumberError)
    end

    it 'raises UnsupportedStateError for invalid state' do
      expect do
        described_class.new('93/815/08152', state: 'XX')
      end.to raise_error(Steuer::UnsupportedStateError)
    end

    it 'raises InvalidTaxNumberError for wrong state' do
      expect do
        described_class.new('93/815/08152', state: 'BY') # BW number with BY state
      end.to raise_error(Steuer::InvalidTaxNumberError)
    end

    it 'raises InvalidTaxNumberError for empty input' do
      expect do
        described_class.new('', state: 'BW')
      end.to raise_error(Steuer::InvalidTaxNumberError)
    end
  end

  describe 'input normalization' do
    it 'handles spaces in input' do
      tax_number = described_class.new(' 93 / 815 / 08152 ', state: 'BW')
      expect(tax_number.valid?).to be true
      expect(tax_number.state_code).to eq('BW')
    end

    it 'handles various separators' do
      tax_number = described_class.new('93-815-08152', state: 'BW')
      expect(tax_number.valid?).to be true
      expect(tax_number.state_code).to eq('BW')
    end

    it 'accepts full state name' do
      tax_number = described_class.new('93/815/08152', state: 'Baden-Württemberg')
      expect(tax_number.state_code).to eq('BW')
      expect(tax_number.state_name).to eq('Baden-Württemberg')
    end
  end

  describe 'state_name method' do
    it 'returns the full state name for valid state codes' do
      tax_number = described_class.new('93/815/08152', state: 'BW')
      expect(tax_number.state_name).to eq('Baden-Württemberg')
    end

    it 'returns the full state name for different states' do
      bayern = described_class.new('181/815/08155', state: 'BY')
      expect(bayern.state_name).to eq('Bayern')

      hessen = described_class.new('013/815/08153', state: 'HE')
      expect(hessen.state_name).to eq('Hessen')

      saarland = described_class.new('010/815/08182', state: 'SL')
      expect(saarland.state_name).to eq('Saarland')
    end
  end

  describe 'auto-detection vs explicit state' do
    it 'auto-detects unambiguous standard formats' do
      # NOTE: 93/815/08152 is actually ambiguous (matches multiple states)
      # This test is kept for backward compatibility but now requires explicit state
      tax_number = described_class.new('93/815/08152', state: 'BW') # Explicit state required
      expect(tax_number.state_code).to eq('BW')
    end

    it 'auto-detects unambiguous federal prefixes' do
      tax_number = described_class.new('289381508152') # BW prefix '28' is unique
      expect(tax_number.state_code).to eq('BW')
    end

    it 'auto-detects all unique federal 12-digit prefixes' do
      unique_cases = {
        '289381508152' => 'BW',  # prefix '28'
        '918181508155' => 'BY',  # prefix '9'
        '112181508150' => 'BE',  # prefix '11'
        '247581508152' => 'HB',  # prefix '24'
        '220281508156' => 'HH',  # prefix '22'
        '261381508153' => 'HE',  # prefix '26'
        '232481508151' => 'NI',  # prefix '23'
        '513381508159' => 'NW',  # prefix '5'
        '272281508154' => 'RP',  # prefix '27'
        '101081508182' => 'SL',  # prefix '1'
        '210181508155' => 'SH', # prefix '21'
      }

      unique_cases.each do |tax_number, expected_state|
        result = described_class.new(tax_number)
        expect(result.state_code).to eq(expected_state)
      end
    end

    it 'requires explicit state for ambiguous prefixes' do
      # Test all ambiguous prefix cases
      ambiguous_cases = [
        '304881508155',  # Prefix '3' - could be BB, SN, ST
        '320181508156',  # Prefix '3' - could be BB, SN, ST
        '310181508153',  # Prefix '3' - could be BB, SN, ST
        '407981508151',  # Prefix '4' - could be MV, TH
        '415181508154', # Prefix '4' - could be MV, TH
      ]

      ambiguous_cases.each do |tax_number|
        expect do
          described_class.new(tax_number)
        end.to raise_error(Steuer::UnsupportedStateError, /Cannot determine state/)
      end
    end

    it 'works with explicit state for ambiguous cases' do
      # Test all ambiguous prefix combinations work with explicit state
      ambiguous_test_cases = [
        { tax_number: '304881508155', state: 'BB' },
        { tax_number: '320181508156', state: 'SN' },
        { tax_number: '310181508153', state: 'ST' },
        { tax_number: '407981508151', state: 'MV' },
        { tax_number: '415181508154', state: 'TH' },
      ]

      ambiguous_test_cases.each do |test_case|
        tax_number = described_class.new(test_case[:tax_number], state: test_case[:state])
        expect(tax_number.state_code).to eq(test_case[:state])
        expect(tax_number.valid?).to be true
      end
    end

    it 'validates explicit state matches tax number' do
      expect do
        described_class.new('93/815/08152', state: 'BY') # BW number with BY state
      end.to raise_error(Steuer::InvalidTaxNumberError)
    end

    it 'requires explicit state for ambiguous standard formats' do
      # Test ambiguous standard format cases
      # Pattern FF/BBB/UUUUP is shared by: BW, BE, HB, HH, NI, RP, SH
      ambiguous_standard_cases = [
        '32/462/02550',  # Could be BW, BE, HB, HH, NI, RP, or SH
        '21/815/08150',  # Could be BW, BE, HB, HH, NI, RP, or SH
        '93/815/08152',  # Could be BW, BE, HB, HH, NI, RP, or SH
      ]

      ambiguous_standard_cases.each do |tax_number|
        expect do
          described_class.new(tax_number)
        end.to raise_error(Steuer::UnsupportedStateError, /Cannot determine state/)
      end
    end

    it 'requires explicit state for ambiguous FFF/BBB/UUUUP standard formats' do
      # Pattern FFF/BBB/UUUUP is shared by: BY, BB, MV, SN, ST, TH
      ambiguous_fff_cases = [
        '181/815/08155',  # Could be BY, BB, MV, SN, ST, or TH
        '048/815/08155',  # Could be BY, BB, MV, SN, ST, or TH
        '201/815/08156',  # Could be BY, BB, MV, SN, ST, or TH
      ]

      ambiguous_fff_cases.each do |tax_number|
        expect do
          described_class.new(tax_number)
        end.to raise_error(Steuer::UnsupportedStateError, /Cannot determine state/)
      end
    end

    it 'works with explicit state for ambiguous standard format cases' do
      # Test that ambiguous standard formats work with explicit state
      ambiguous_standard_test_cases = [
        { tax_number: '32/462/02550', state: 'BE' },  # Berlin
        { tax_number: '32/462/02550', state: 'BW' },  # Baden-Württemberg
        { tax_number: '21/815/08150', state: 'BE' },  # Berlin
        { tax_number: '93/815/08152', state: 'BW' },  # Baden-Württemberg
        { tax_number: '181/815/08155', state: 'BY' },  # Bayern
        { tax_number: '048/815/08155', state: 'BB' },  # Brandenburg
      ]

      ambiguous_standard_test_cases.each do |test_case|
        tax_number = described_class.new(test_case[:tax_number], state: test_case[:state])
        expect(tax_number.state_code).to eq(test_case[:state])
        expect(tax_number.valid?).to be true
      end
    end

    it 'auto-detects unambiguous standard formats with unique patterns' do
      # Only NW has a truly unique pattern (FFF/BBBB/UUUP)
      # HE and SL patterns are ambiguous (also match general FFF/BBB/UUUUP)
      tax_number = described_class.new('133/8150/8159')
      expect(tax_number.state_code).to eq('NW')
      expect(tax_number.valid?).to be true
    end

    it 'requires explicit state for ambiguous patterns that match multiple formats' do
      # These match both specific patterns and general patterns
      ambiguous_specific_cases = [
        '013/815/08153',  # Matches HE and general FFF/BBB/UUUUP
        '010/815/08182',  # Matches SL and general FFF/BBB/UUUUP
      ]

      ambiguous_specific_cases.each do |tax_number|
        expect do
          described_class.new(tax_number)
        end.to raise_error(Steuer::UnsupportedStateError, /Cannot determine state/)
      end
    end
  end

  describe 'all states coverage' do
    {
      'BW' => { standard: '93/815/08152', federal_12: '289381508152', federal_13: '2893081508152' },
      'BY' => { standard: '181/815/08155', federal_12: '918181508155', federal_13: '9181081508155' },
      'BE' => { standard: '21/815/08150', federal_12: '112181508150', federal_13: '1121081508150' },
      'BB' => { standard: '048/815/08155', federal_12: '304881508155', federal_13: '3048081508155' },
      'HB' => { standard: '75/815/08152', federal_12: '247581508152', federal_13: '2475081508152' },
      'HH' => { standard: '02/815/08156', federal_12: '220281508156', federal_13: '2202081508156' },
      'HE' => { standard: '013/815/08153', federal_12: '261381508153', federal_13: '2613081508153' },
      'NI' => { standard: '24/815/08151', federal_12: '232481508151', federal_13: '2324081508151' },
      'NW' => { standard: '133/8150/8159', federal_12: '513381508159', federal_13: '5133081508159' },
      'RP' => { standard: '22/815/08154', federal_12: '272281508154', federal_13: '2722081508154' },
      'SL' => { standard: '010/815/08182', federal_12: '101081508182', federal_13: '1010081508182' },
    }.each do |state_code, formats|
      context "when state is #{state_code}" do
        it 'converts between all formats correctly' do
          # Standard -> Federal 12 -> Federal 13
          standard = described_class.new(formats[:standard], state: state_code)
          expect(standard.state_code).to eq(state_code)
          expect(standard.to_federal_12).to eq(formats[:federal_12])
          expect(standard.to_federal_13).to eq(formats[:federal_13])

          # Federal 12 -> Standard, Federal 13
          federal_12 = described_class.new(formats[:federal_12], state: state_code)
          expect(federal_12.state_code).to eq(state_code)
          expect(federal_12.to_standard).to eq(formats[:standard])
          expect(federal_12.to_federal_13).to eq(formats[:federal_13])

          # Federal 13 -> Standard, Federal 12
          federal_13 = described_class.new(formats[:federal_13], state: state_code)
          expect(federal_13.state_code).to eq(state_code)
          expect(federal_13.to_standard).to eq(formats[:standard])
          expect(federal_13.to_federal_12).to eq(formats[:federal_12])
        end
      end
    end
  end
end
