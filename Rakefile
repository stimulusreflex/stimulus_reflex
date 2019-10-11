# frozen_string_literal: true

require "bundler/gem_tasks"

task default: [:test]

task :test do
  system("bin/ruby_test") && system("cd javascript && yarn run test")
end
