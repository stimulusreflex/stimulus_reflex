# frozen_string_literal: true

require File.expand_path("lib/stimulus_reflex/version", __dir__)

Gem::Specification.new do |gem|
  gem.name = "stimulus_reflex"
  gem.license = "MIT"
  gem.version = StimulusReflex::VERSION
  gem.authors = ["Nathan Hopkins"]
  gem.email = ["natehop@gmail.com"]
  gem.homepage = "https://github.com/stimulusreflex/stimulus_reflex"
  gem.summary = "Build reactive applications with the Rails tooling you already know and love."
  gem.post_install_message = <<~MESSAGE
    Finish installation by running:

    rake stimulus_reflex:install

    Get support for StimulusReflex and CableReady on Discord:

    https://discord.gg/stimulus-reflex

  MESSAGE

  gem.metadata = {
    "bug_tracker_uri" => "https://github.com/stimulusreflex/stimulus_reflex/issues",
    "changelog_uri" => "https://github.com/stimulusreflex/stimulus_reflex/CHANGELOG.md",
    "documentation_uri" => "https://docs.stimulusreflex.com",
    "homepage_uri" => gem.homepage,
    "source_code_uri" => gem.homepage
  }

  gem.files = Dir["app/**/*", "lib/**/*", "bin/*", "[A-Z]*"]
  gem.test_files = Dir["test/**/*.rb"]

  rails_version = ">= 5.2"
  gem.add_dependency "actioncable", rails_version
  gem.add_dependency "actionpack", rails_version
  gem.add_dependency "actionview", rails_version
  gem.add_dependency "activesupport", rails_version

  gem.add_dependency "cable_ready", "5.0.0.pre8"
  gem.add_dependency "nokogiri"
  gem.add_dependency "rack"
  gem.add_dependency "redis"

  gem.add_development_dependency "bundler", "~> 2.0"
  gem.add_development_dependency "mocha"
  gem.add_development_dependency "pry"
  gem.add_development_dependency "pry-nav"
  gem.add_development_dependency "rails", rails_version
  gem.add_development_dependency "rake"
  gem.add_development_dependency "standardrb", "~> 1.0"
end
