# frozen_string_literal: true

class StimulusReflex::SanityChecker
  JSON_VERSION_FORMAT = /(\d+\.\d+\.\d+.*)"/

  def self.check!
    return if StimulusReflex.config.on_failed_sanity_checks == :ignore

    instance = new
    instance.check_caching_enabled
    instance.check_javascript_package_version
  end

  def check_caching_enabled
    unless caching_enabled?
      warn_and_exit <<~WARN
        Stimulus Reflex requires caching to be enabled. Caching allows the session to be modified during ActionCable requests.
        To enable caching in development, run:
            rails dev:cache
      WARN
    end

    unless not_null_store?
      warn_and_exit <<~WARN
        Stimulus Reflex requires caching to be enabled. Caching allows the session to be modified during ActionCable requests.
        But your config.cache_store is set to :null_store, so it won't work.
      WARN
    end
  end

  def check_javascript_package_version
    if javascript_package_version.nil?
      warn_and_exit <<~WARN
        Can't locate the stimulus_reflex NPM package.
        Either add it to your package.json as a dependency or use "yarn link stimulus_reflex" if you are doing development.
      WARN
    end

    unless javascript_version_matches?
      warn_and_exit <<~WARN
        The Stimulus Reflex javascript package version (#{javascript_package_version}) does not match the Rubygem version (#{gem_version}).
        To update the Stimulus Reflex npm package:
            yarn upgrade stimulus_reflex@#{gem_version}
      WARN
    end
  end

  private

  def caching_enabled?
    Rails.application.config.action_controller.perform_caching
  end

  def not_null_store?
    Rails.application.config.cache_store != :null_store
  end

  def javascript_version_matches?
    javascript_package_version == gem_version
  end

  def gem_version
    @_gem_version ||= StimulusReflex::VERSION.gsub(".pre", "-pre")
  end

  def javascript_package_version
    @_js_version ||= find_javascript_package_version
  end

  def find_javascript_package_version
    if (match = search_file(package_json_path, regex: /version/))
      match[JSON_VERSION_FORMAT, 1]
    end
  end

  def search_file(path, regex:)
    return unless File.exist?(path)
    File.foreach(path).grep(regex).first
  end

  def package_json_path
    Rails.root.join("node_modules", "stimulus_reflex", "package.json")
  end

  def warn_and_exit(text)
    puts "WARNING:"
    puts text
    exit_with_info if StimulusReflex.config.on_failed_sanity_checks == :exit
  end

  def exit_with_info
    puts
    puts <<~INFO
      If you know what you are doing and you want to start the application anyway,
      you can add the following directive to an initializer:
            StimulusReflex.config.on_failed_sanity_checks = :warn
    INFO
    exit
  end
end
