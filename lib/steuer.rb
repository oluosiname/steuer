# frozen_string_literal: true

require_relative 'steuer/version'
require_relative 'steuer/steuernummer'
require_relative 'steuer/errors'

module Steuer
  class << self
    def steuernummer(tax_number, state: nil)
      Steuernummer.new(tax_number, state: state)
    end
  end
end
