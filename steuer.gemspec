# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = 'steuer'
  spec.version       = Steuer::VERSION
  spec.authors       = ['Olumuyiwa Osiname']
  spec.email         = ['oluosiname@gmail.com']

  spec.summary       = 'German tax system utilities - tax numbers, VAT validation, and more'
  spec.description   = 'A Ruby gem for German tax system utilities including Steuernummer conversion between formats, VAT validation, and other tax-related functionality'
  spec.homepage      = 'https://github.com/oluosiname/steuer'
  spec.license       = 'MIT'

  spec.files         = Dir['lib/**/*', 'README.md', 'LICENSE']
  spec.require_paths = ['lib']

  spec.add_development_dependency 'pry', '~> 0.15.1'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 1.56.0'
  spec.add_development_dependency 'rubocop-factory_bot', '~> 2.24.0'
  spec.add_development_dependency 'rubocop-performance', '~> 1.19.0'
  spec.add_development_dependency 'rubocop-rspec', '~> 2.24.0'
  spec.add_development_dependency 'rubocop-shopify', '~> 2.14'

  spec.required_ruby_version = '>= 3.2.0'
end
