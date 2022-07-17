# frozen_string_literal: true

require "rails/generators"
require "stimulus_reflex/installer_helper"

module StimulusReflex
  class ConfigGenerator < Rails::Generators::Base
    desc "Creates a StimulusReflex config in app/javascript/config/stimulus_reflex.js"
    source_root File.expand_path("templates", __dir__)

    def create_config
      javascript_path = StimulusReflex::InstallerHelper.javascript_path

      copy_file "app/javascript/config/stimulus_reflex.js"

      if File.exist?(Rails.root.join("#{javascript_path}/config/index.js"))
        append_to_file "#{javascript_path}/config/index.js", 'import "./stimulus_reflex"'
      else
        copy_file "#{javascript_path}/config/index.js"
      end

      paths = [
        "#{javascript_path}/application.js",
        "#{javascript_path}/application.ts"
      ]

      paths.each do |path|
        if File.exist?(path)
          if StimulusReflex::InstallerHelper.importmap?
            append_to_file path, 'import "config"'
          else
            append_to_file path, 'import "./config"'
          end
        end
      end
    end
  end
end
