module SanityChecker
  NODE_VERSION_FORMAT = /(\d+\.\d+\.\d+.*):/
  JSON_VERSION_FORMAT = /(\d+\.\d+\.\d+.*)"/

  class << self
    def check_caching_enabled
      unless caching_enabled?
        puts <<~WARN
          Stimulus Reflex requires caching to be enabled. Caching allows the session to be modified during ActionCable requests.
          To enable caching in development, run:

            rails dev:cache
        WARN
      end
    end

    def check_javascript_package_version
      if javascript_package_version.nil?
        puts <<~WARN
          Can't locate the stimulus_reflex NPM package.
          Either add it to your package.json as a dependency or use "yarn link stimulus_reflex" if you are doing development.
        WARN
      end

      unless javascript_version_matches?
        puts <<~WARN
          The Stimulus Reflex javascript package version (#{javascript_package_version}) does not match the Rubygem version (#{gem_version}).
          To update the Stimulus Reflex npm package:

            yarn upgrade stimulus_reflex@#{gem_version}
        WARN
      end
    end

    private

    def caching_enabled?
      Rails.application.config.action_controller.perform_caching &&
        Rails.application.config.cache_store != :null_store
    end

    def javascript_version_matches?
      javascript_package_version == gem_version
    end

    def gem_version
      StimulusReflex::VERSION.gsub(".pre", "-pre")
    end

    def javascript_package_version
      if File.exist?(yarn_lock_path)
        match = File.foreach(yarn_lock_path).grep(/^stimulus_reflex/)
        return match.first[NODE_VERSION_FORMAT, 1] if match.present?
      end

      if File.exist?(yarn_link_path)
        match = File.foreach(yarn_link_path).grep(/version/)
        return match.first[JSON_VERSION_FORMAT, 1] if match.present?
      end
    end

    def yarn_lock_path
      Rails.root.join("yarn.lock")
    end

    def yarn_link_path
      Rails.root.join("node_modules", "stimulus_reflex", "package.json")
    end
  end
end
