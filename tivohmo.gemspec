# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'tivohmo/version'

Gem::Specification.new do |spec|
  spec.name          = "tivohmo"
  spec.version       = TivoHMO::VERSION
  spec.authors       = ["Matt Conway"]
  spec.email         = ["matt@conwaysplace.com"]
  spec.summary       = %q{Ruby SDK for Tivo Home Media Option}
  spec.description   = %q{Allows one to author Tivo HMO applications using ruby}
  spec.homepage      = ""
  spec.license       = "LGPL"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "awesome_print"
  spec.add_development_dependency "rspec"

  # core dependencies
  spec.add_dependency "activesupport"
  spec.add_dependency "gem_logger"
  spec.add_dependency "sigdump"
  spec.add_dependency "clamp"
  spec.add_dependency "sinatra"
  spec.add_dependency "builder"
  spec.add_dependency "puma"

  # filesystem adapter dependencies, make optional?
  spec.add_dependency "listen"
  spec.add_dependency "streamio-ffmpeg"

  # plex adapter dependencies, make optional?
  spec.add_dependency "plex-ruby"
end
