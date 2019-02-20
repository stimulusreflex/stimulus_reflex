require File.expand_path("../lib/stimulus_reflex/version", __FILE__)

Gem::Specification.new do |gem|
  gem.name        = "stimulus_reflex"
  gem.license     = "MIT"
  gem.version     = StimulusReflex::VERSION
  gem.authors     = ["Nathan Hopkins", "Ron Cooke"]
  gem.email       = ["natehop@gmail.com", "brasco@thebrascode.com"]
  gem.homepage    = "https://github.com/hopsoft/stimulus_reflex"
  gem.summary     = "Server side reactive behavior for Stimulus"

  gem.files       = Dir["lib/**/*.rb", "app/assets/javascripts/stimulus_reflex.js", "bin/*", "[A-Z]*"]
  gem.test_files  = Dir["test/**/*.rb"]

  gem.add_dependency "rack"
  gem.add_dependency "nokogiri"
  gem.add_dependency "actioncable", ">= 5.2.1"
  gem.add_dependency "actionpack", ">= 5.2.1"
  gem.add_dependency "cable_ready", ">= 2.0.7"

  gem.add_development_dependency "bundler", "~> 1.16"
  gem.add_development_dependency "rake"
  gem.add_development_dependency "standardrb"
end
