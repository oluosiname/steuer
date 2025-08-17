# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Steuer do
  describe '.steuernummer' do
    it 'creates a Steuernummer instance' do
      tax_number = described_class.steuernummer('93/815/08152', state: 'BW')
      expect(tax_number).to be_a(Steuer::Steuernummer)
    end

    it 'passes state to Steuernummer' do
      tax_number = described_class.steuernummer('93/815/08152', state: 'BW')
      expect(tax_number.state_code).to eq('BW')
    end

    it 'auto-detects state from standard format' do
      tax_number = described_class.steuernummer('93/815/08152')  # No state provided
      expect(tax_number.state_code).to eq('BW')
    end

    it 'auto-detects state from unambiguous federal format' do
      tax_number = described_class.steuernummer('289381508152')  # BW has unique prefix '28'
      expect(tax_number.state_code).to eq('BW')
    end

    it 'requires state for ambiguous federal format' do
      expect do
        described_class.steuernummer('304881508155') # Prefix '3' is ambiguous
      end.to raise_error(Steuer::UnsupportedStateError, /Cannot determine state/)
    end

    it 'accepts explicit state for ambiguous cases' do
      tax_number = described_class.steuernummer('304881508155', state: 'BB')
      expect(tax_number.state_code).to eq('BB')
    end

    it 'accepts full state name' do
      tax_number = described_class.steuernummer('93/815/08152', state: 'Baden-Württemberg')
      expect(tax_number.state_code).to eq('BW')
    end
  end

  # Future: when we add VAT, we can add shared examples here
  # describe '.vat' do
  #   it_behaves_like 'a tax validation service'
  # end
end
