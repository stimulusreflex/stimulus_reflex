# frozen_string_literal: true

class StimulusReflex::Element < OpenStruct
  attr_reader :attributes, :data_attributes

  def initialize(attrs = {})
    @attributes = HashWithIndifferentAccess.new(attrs || {})
    @data_attributes = attributes.each_with_object(HashWithIndifferentAccess.new) { |(key, value), memo|
      memo[key.delete_prefix("data-")] = value if key.start_with?("data-")
    }
    super attributes.merge(attributes.transform_keys(&:underscore))
  end

  def dataset
    @dataset ||= OpenStruct.new(data_attributes.merge(data_attributes.transform_keys(&:underscore)))
  end
end
