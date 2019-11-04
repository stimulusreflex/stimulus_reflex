require File.expand_path("../lib/stimulus_reflex/version", __FILE__)

Gem::Specification.new do |gem|
  gem.name = "stimulus_reflex"
  gem.license = "MIT"
  gem.version = StimulusReflex::VERSION
  gem.authors = ["Nathan Hopkins"]
  gem.email = ["natehop@gmail.com"]
  gem.homepage = "https://github.com/hopsoft/stimulus_reflex"
  gem.summary = "Build reactive applications with the Rails tooling you already know and love."

  gem.files = Dir["lib/**/*", "bin/*", "[A-Z]*"]
  gem.test_files = Dir["test/**/*.rb"]

  gem.add_dependency "rack"
  gem.add_dependency "nokogiri"
  gem.add_dependency "rails", ">= 5.2"
  gem.add_dependency "cable_ready", ">= 4.0"

  gem.add_development_dependency "bundler", "~> 2.0"
  gem.add_development_dependency "rake"
  gem.add_development_dependency "pry"
  gem.add_development_dependency "pry-nav"
  gem.add_development_dependency "standardrb"
end
