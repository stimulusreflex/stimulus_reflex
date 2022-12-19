# frozen_string_literal: true

require "rails/generators"
require "stimulus_reflex/version"

module StimulusReflex
  class InitializerGenerator < Rails::Generators::Base
    desc "Creates a StimulusReflex initializer in config/initializers"
    source_root File.expand_path("templates", __dir__)
    class_options timeout: 1

    def copy_initializer_file
      initializer_src = fetch("/config/initializers/stimulus_reflex.rb")
      initializer_path = Rails.root.join("config/initializers/stimulus_reflex.rb")
      copy_file initializer_src, initializer_path
    end

    private

    def fetch(file)
      working = Rails.root.join("tmp/stimulus_reflex_installer/working")

      begin
        tmp_path = working.to_s + file
        url = "https://raw.githubusercontent.com/stimulusreflex/stimulus_reflex/#{StimulusReflex::BRANCH}/lib/generators/stimulus_reflex/templates#{file}"
        FileUtils.mkdir_p(tmp_path.split("/")[0..-2].join("/"))
        File.write(tmp_path, URI.open(url, open_timeout: options[:timeout].to_i, read_timeout: options[:timeout].to_i).read) # standard:disable Security/Open
        tmp_path
      rescue
        source_paths.first + file
      end
    end
  end
end
