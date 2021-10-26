# frozen_string_literal: true

require "bundler/gem_tasks"
require "rails/test_unit/runner"
require "github_changelog_generator/task"

task :test_javascript do |task|
  system "yarn run test"
end

task :test_ruby do |task|
  Rails::TestUnit::Runner.run
end

task test: [:test_javascript, :test_ruby]
task default: [:test]

GitHubChangelogGenerator::RakeTask.new :changelog do |config|
  config.user = "stimulusreflex"
  config.project = "stimulus_reflex"
  config.exclude_labels = %w[duplicate question invalid wontfix nodoc]
  config.token = ENV["GITHUB_CHANGELOG_GENERATOR_TOKEN"]
end
