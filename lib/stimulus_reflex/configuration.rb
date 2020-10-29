# frozen_string_literal: true

module StimulusReflex
  class << self
    def configure
      yield configuration
    end

    def configuration
      @configuration ||= Configuration.new
    end

    alias config configuration
  end

  class Configuration
    attr_accessor :example # put your attr_accessors here, like `attr_accessor: debug`, remove this line when you do.

    def initialize
      @example = true # put your defaults here like `@debug = true, remove this line when you do.
    end
  end
end
