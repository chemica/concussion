# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'concussion/version'

Gem::Specification.new do |spec|
  spec.name          = "concussion"
  spec.version       = Concussion::VERSION
  spec.authors       = ["Benjamin Randles-Dunkley"]
  spec.email         = ["ben@chemica.co.uk"]

  spec.summary       = %q{An addition to the Suckerpunch gem to allow delayed jobs that survive a server reset.}
  spec.description   = %q{Sucker Punch is an awesome gem which allows background tasks to be run from the current
                          process. They can be set to run in the future, but they will disappear and not get run if the
                          server or process running the jobs is stopped or restarted. Concussion provides a thin wrapper
                          around Suckerpunch job objects, persisting them to an external storage system of your choice.
                          When the server is restarted, any unprocessed jobs will be run immediately while future jobs
                          will be reinstated to be run at the appropriate time.}
  spec.homepage      = "https://github.com/chemica/concussion"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "sucker_punch", "~> 1.0"

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest"
end
