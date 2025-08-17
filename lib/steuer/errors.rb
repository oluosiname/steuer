# frozen_string_literal: true

module Steuer
  class Error < StandardError; end
  class InvalidTaxNumberError < Error; end
  class UnsupportedStateError < Error; end
  class ValidationError < Error; end
end
