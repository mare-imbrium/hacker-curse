# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hacker/curse/version'

Gem::Specification.new do |spec|
  spec.name          = "hacker-curse"
  spec.version       = Hacker::Curse::VERSION
  spec.authors       = ["kepler"]
  spec.email         = ["githubkepler.50s@gishpuppy.com"]
  spec.summary       = %q{View hacker news and reddit articles on terminal using ncurses}
  spec.description   = %q{View Hacker News and reddit articles on terminal using ncurses}
  spec.homepage      = "https://github.com/mare-imbrium/hacker-curse"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake", ">= 0.9.6"
  spec.add_runtime_dependency "canis", ">= 0.0.3", ">= 0.0.3"
  spec.add_runtime_dependency "nokogiri"
end
