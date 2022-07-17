require "cable_ready/installer_helper"

module StimulusReflex
  class InstallerHelper < ::CableReady::InstallerHelper
    def self.stimulus_reflex_gem_version
      StimulusReflex::VERSION.gsub(".pre", "-pre")
    end
  end
end
