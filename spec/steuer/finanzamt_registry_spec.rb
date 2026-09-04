# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Steuer::FinanzamtRegistry do
  describe '.name_for' do
    it 'resolves a known BUFA-Nr to its office name' do
      expect(described_class.name_for('1010')).to eq('Saarlouis')
    end

    it 'accepts an integer code' do
      expect(described_class.name_for(1010)).to eq('Saarlouis')
    end

    it 'returns nil for an unknown code' do
      expect(described_class.name_for('9999')).to be_nil
    end
  end

  describe '.state_for' do
    it 'derives the state from an unambiguous federal prefix' do
      expect(described_class.state_for('1010')).to eq('SL')
    end

    it 'is nil where the federal prefix is shared between states' do
      shared = described_class.entries.keys.find { |code| code.start_with?('3') }

      expect(described_class.state_for(shared)).to be_nil
    end
  end

  describe '.known?' do
    it 'distinguishes present from absent codes' do
      expect(described_class.known?('1010')).to be(true)
      expect(described_class.known?('9999')).to be(false)
    end
  end

  describe '.revision' do
    it 'reports the bundled table revision date' do
      expect(described_class.revision).to match(/\A\d{4}-\d{2}-\d{2}\z/)
    end
  end

  describe 'bundled data' do
    it 'keys every office by a four-digit BUFA-Nr' do
      expect(described_class.entries.keys).to all(match(/\A\d{4}\z/))
    end

    it 'gives every office a non-empty name' do
      names = described_class.entries.values.map { |entry| entry[:name] }

      expect(names).to all(be_a(String))
      expect(names.map(&:strip)).to all(satisfy { |name| !name.empty? })
    end
  end
end
