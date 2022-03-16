# frozen_string_literal: true

require "bundler/gem_tasks"
require "rails/test_unit/runner"

task :test_javascript do |task|
  system "yarn run test"
end

task :test_ruby do |task|
  Rails::TestUnit::Runner.run
end

task test: [:test_javascript, :test_ruby]
task default: [:test]
