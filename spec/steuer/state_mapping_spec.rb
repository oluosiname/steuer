# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Steuer::StateMapping do
  describe '.find_state_by_standard_format' do
    it 'detects Baden-Württemberg from FF/BBB/UUUUP pattern' do
      result = described_class.find_state_by_standard_format('93/815/08152')
      expect(result).to eq('BW')
    end

    it 'detects Bayern from FFF/BBB/UUUUP pattern' do
      result = described_class.find_state_by_standard_format('181/815/08155')
      expect(result).to eq('BY')
    end

    it 'detects Nordrhein-Westfalen from FFF/BBBB/UUUP pattern' do
      result = described_class.find_state_by_standard_format('133/8150/8159')
      expect(result).to eq('NW')
    end

    it 'detects Hessen from 0FF/BBB/UUUUP pattern' do
      result = described_class.find_state_by_standard_format('013/815/08153')
      expect(result).to eq('HE')
    end

    it 'returns nil for invalid format' do
      result = described_class.find_state_by_standard_format('invalid')
      expect(result).to be_nil
    end

    it 'returns nil for non-matching pattern' do
      result = described_class.find_state_by_standard_format('1/2/3') # Too short, doesn't match any pattern
      expect(result).to be_nil
    end
  end

  describe '.find_state_by_federal_12' do
    it 'detects states with unique prefixes' do
      expect(described_class.find_state_by_federal_12('289381508152')).to eq('BW')  # prefix '28'
      expect(described_class.find_state_by_federal_12('918181508155')).to eq('BY')  # prefix '9'
      expect(described_class.find_state_by_federal_12('112181508150')).to eq('BE')  # prefix '11'
      expect(described_class.find_state_by_federal_12('247581508152')).to eq('HB')  # prefix '24'
      expect(described_class.find_state_by_federal_12('220281508156')).to eq('HH')  # prefix '22'
      expect(described_class.find_state_by_federal_12('261381508153')).to eq('HE')  # prefix '26'
      expect(described_class.find_state_by_federal_12('232481508151')).to eq('NI')  # prefix '23'
      expect(described_class.find_state_by_federal_12('513381508159')).to eq('NW')  # prefix '5'
      expect(described_class.find_state_by_federal_12('272281508154')).to eq('RP')  # prefix '27'
      expect(described_class.find_state_by_federal_12('101081508182')).to eq('SL')  # prefix '1'
      expect(described_class.find_state_by_federal_12('210181508155')).to eq('SH')  # prefix '21'
    end

    it 'returns nil for invalid length' do
      expect(described_class.find_state_by_federal_12('123')).to be_nil
      expect(described_class.find_state_by_federal_12('12345678901234')).to be_nil
    end

    it 'returns nil for unknown prefix' do
      expect(described_class.find_state_by_federal_12('999999999999')).to be_nil
    end

    it 'prioritizes longer prefixes over shorter ones' do
      # '28' should match before '2', '11' should match before '1'
      expect(described_class.find_state_by_federal_12('289381508152')).to eq('BW')  # not a '2' state
      expect(described_class.find_state_by_federal_12('112181508150')).to eq('BE')  # not SL ('1')
    end
  end

  describe '.find_state_by_federal_13' do
    it 'detects states with unique prefixes' do
      expect(described_class.find_state_by_federal_13('2893081508152')).to eq('BW')  # prefix '28'
      expect(described_class.find_state_by_federal_13('9181081508155')).to eq('BY')  # prefix '9'
      expect(described_class.find_state_by_federal_13('1121081508150')).to eq('BE')  # prefix '11'
    end

    it 'returns nil for invalid length' do
      expect(described_class.find_state_by_federal_13('123')).to be_nil
      expect(described_class.find_state_by_federal_13('123456789012345')).to be_nil
    end

    it 'prioritizes longer prefixes over shorter ones' do
      expect(described_class.find_state_by_federal_13('2893081508152')).to eq('BW')  # not a '2' state
      expect(described_class.find_state_by_federal_13('1121081508150')).to eq('BE')  # not SL ('1')
    end
  end
end
