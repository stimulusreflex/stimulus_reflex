# frozen_string_literal: true

class StimulusReflex::SanityChecker
  NODE_VERSION_FORMAT = /(\d+\.\d+\.\d+.*):/
  JSON_VERSION_FORMAT = /(\d+\.\d+\.\d+.*)"/

  def self.check!
    instance = new
    instance.check_caching_enabled
    instance.check_javascript_package_version
  end

  def check_caching_enabled
    unless caching_enabled?
      puts <<~WARN
        WARNING: Stimulus Reflex requires caching to be enabled. Caching allows the session to be modified during ActionCable requests.
        To enable caching in development, run:
            rails dev:cache
      WARN
    end
  end

  def check_javascript_package_version
    if javascript_package_version.nil?
      puts <<~WARN
        WARNING: Can't locate the stimulus_reflex NPM package.
        Either add it to your package.json as a dependency or use "yarn link stimulus_reflex" if you are doing development.
      WARN
    end

    unless javascript_version_matches?
      puts <<~WARN
        WARNING: The Stimulus Reflex javascript package version (#{javascript_package_version}) does not match the Rubygem version (#{gem_version}).
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
    @_gem_version ||= StimulusReflex::VERSION.gsub(".pre", "-pre")
  end

  def javascript_package_version
    return @_js_version if defined?(@_js_version)
    @_js_version = find_javascript_package_version
  end

  def find_javascript_package_version
    if (match = search_file(yarn_lock_path, regex: /^stimulus_reflex/))
      match[NODE_VERSION_FORMAT, 1]
    elsif (match = search_file(yarn_link_path, regex: /version/))
      match[JSON_VERSION_FORMAT, 1]
    end
  end

  def search_file(path, regex:)
    return unless File.exist?(path)
    File.foreach(path).grep(regex).first
  end

  def yarn_lock_path
    Rails.root.join("yarn.lock")
  end

  def yarn_link_path
    Rails.root.join("node_modules", "stimulus_reflex", "package.json")
  end
end
