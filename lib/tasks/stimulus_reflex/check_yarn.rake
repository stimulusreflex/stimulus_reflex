# frozen_string_literal: true

namespace :stimulus_reflex do
  desc "Verifies Yarn is installed"
  task :check_yarn do
    yarn_version = `yarn --version`
    raise Errno::ENOENT if yarn_version.blank?
  rescue Errno::ENOENT
    warn "Yarn not installed. Please download and install Yarn from https://yarnpkg.com/lang/en/docs/install/"
    warn "Exiting!" && exit!
  end
end
