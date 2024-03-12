# frozen_string_literal: true

class StimulusReflex::ReflexFactory
  attr_reader :channel, :data

  delegate :reflex_name, :method_name, to: :data

  def initialize(channel, data)
    @channel = channel
    @data = StimulusReflex::ReflexData.new(data)
  end

  def call
    verify_method_name!
    reflex_class.new(channel, reflex_data: data)
  end

  private

  def verify_method_name!
    return if default_reflex?

    argument_error = ArgumentError.new("Reflex method '#{method_name}' is not defined on class '#{reflex_name}' or on any of its ancestors")

    if reflex_method.nil?
      raise argument_error
    end

    if !safe_ancestors.include?(reflex_method.owner)
      raise argument_error
    end
  end

  def reflex_class
    @reflex_class ||= reflex_name.constantize.tap do |klass|
      unless klass.ancestors.include?(StimulusReflex::Reflex)
        raise ArgumentError.new("#{reflex_name} is not a StimulusReflex::Reflex")
      end
    end
  end

  def reflex_method
    if reflex_class.public_instance_methods.include?(method_name.to_sym)
      reflex_class.public_instance_method(method_name)
    end
  end

  def default_reflex?
    method_name == "default_reflex" && reflex_method.owner == ::StimulusReflex::Reflex
  end

  def safe_ancestors
    # We want to include every class and module up to the `StimulusReflex::Reflex` class,
    # but not the StimulusReflex::Reflex itself
    reflex_class_index = reflex_class.ancestors.index(StimulusReflex::Reflex) - 1

    reflex_class.ancestors.to(reflex_class_index)
  end
end
