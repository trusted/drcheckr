# frozen_string_literal: true

require_relative 'lib/drcheckr/version'

Gem::Specification.new do |spec|
  spec.name = 'drcheckr'
  spec.version = Drcheckr::VERSION
  spec.authors = ["André Piske"]
  spec.email = ["andrepiske@gmail.com"]
  spec.licenses = ['MIT']

  spec.summary = "Dockerfile dependency tracker"
  spec.description = "Tracks dependencies and generates Dockerfiles using ERB"
  spec.homepage = "https://github.com/trusted/drcheckr"
  spec.required_ruby_version = ">= 3.2.0"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.glob([ "lib/**/*.rb", "bin/*" ])

  spec.bindir = "bin"
  spec.executables = spec.files.grep(%r{\Abin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'excon', '~> 0.111'
  spec.add_dependency 'tilt', '~> 2.4'
end
