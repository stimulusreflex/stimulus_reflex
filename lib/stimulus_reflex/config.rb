# frozen_string_literal: true

module StimulusReflex
  class << self
    def configure
      yield config
    end

    def config
      @config ||= Config.new
    end
  end

  class Config
    attr_accessor :debugging, :logging

    def initialize
      @debugging = false
      @logging = []
    end
  end
end
