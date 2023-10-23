# frozen_string_literal: true

class StimulusReflex::ReflexFactory
  attr_reader :channel, :data

  delegate :reflex_name, to: :data

  def initialize(channel, data)
    @channel = channel
    @data = StimulusReflex::ReflexData.new(data)
  end

  def call
    reflex_class.new(channel, reflex_data: data)
  end

  private

  def reflex_class
    reflex_name.constantize.tap do |klass|
      unless klass.ancestors.include?(StimulusReflex::Reflex)
        raise ArgumentError.new("#{reflex_name} is not a StimulusReflex::Reflex")
      end
    end
  end
end
