require 'rails/generators/named_base'

module StimulusReflex
  class ControllerGenerator < ::Rails::Generators::NamedBase
    source_root File.expand_path('../templates', __dir__)
    desc 'This generator creates server-side Stimulus controllers in app/stimulus_controllers.'

    def create_controller
      template 'stimulus_controller.rb', "app/stimulus_controllers/#{name}_controller.rb"
    end
  end
end
