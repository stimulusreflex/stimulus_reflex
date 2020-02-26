# frozen_string_literal: true

require "bundler/gem_tasks"
require "rails/test_unit/runner"

task default: [:test]

task :test do |task|
  return 1 unless system("cd javascript && yarn run test")
  Rails::TestUnit::Runner.run
end

task :test_ruby do |task|
  Rails::TestUnit::Runner.run
end
