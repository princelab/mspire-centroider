# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mspire/centroider/version'

Gem::Specification.new do |spec|
  spec.name          = "mspire-centroider"
  spec.version       = Mspire::Centroider::VERSION
  spec.authors       = ["Jamison Dance", "John T. Prince"]
  spec.email         = ["jtprince@gmail.com"]
  spec.description   = %q{centroids profile spectra (typically for mass spectrometry data)}
  spec.summary       = %q{centroids profile spectra (typically for mass spectrometry data). }
  spec.homepage      = "http://github.com/princelab/mspire-centroider"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  [
    #["nokogiri", "~> 1.6.2"],
  ].each do |args|
    spec.add_dependency(*args)
  end

  [
    ["bundler", "~> 1.6.2"],
    ["rake"],
    ["rspec", "~> 2.14.1"], 
    ["rdoc", "~> 4.1.1"], 
    ["simplecov", "~> 0.8.2"],
    ["coveralls"],
  ].each do |args|
    spec.add_development_dependency(*args)
  end

end
