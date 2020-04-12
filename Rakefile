# frozen_string_literal: true

require "bundler/gem_tasks"
require "rails/test_unit/runner"
require "github_changelog_generator/task"

task default: [:test]

task :test do |task|
  return 1 unless system("cd javascript && yarn run test")
  Rails::TestUnit::Runner.run
end

task :test_ruby do |task|
  Rails::TestUnit::Runner.run
end

GitHubChangelogGenerator::RakeTask.new :changelog do |config|
  config.add_sections = {dependencies: {prefix: "**Dependencies:**", labels: ["dependencies"]}}
  config.exclude_labels = ["duplicate", "question", "invalid", "wontfix", "nodoc"]
  config.user = "hopsoft"
  config.project = "stimulus_reflex"
  config.token = ENV["GITHUB_TOKEN"]
end
