# frozen_string_literal: true

module StimulusReflex
  class ReflexMethodInvocationPolicy
    attr_reader :arguments, :required_params, :optional_params

    def initialize(method, arguments)
      @arguments = arguments
      @required_params = method.parameters.select { |(kind, _)| kind == :req }
      @optional_params = method.parameters.select { |(kind, _)| kind == :opt }
    end

    def no_arguments?
      arguments.size == 0 && required_params.size == 0
    end

    def arguments?
      arguments.size >= required_params.size && arguments.size <= required_params.size + optional_params.size
    end

    def unknown?
      return false if no_arguments?
      return false if arguments?

      true
    end
  end
end
