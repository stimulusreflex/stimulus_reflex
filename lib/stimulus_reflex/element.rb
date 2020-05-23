# frozen_string_literal: true

class StimulusReflex::Element < OpenStruct
  attr_reader :attributes, :data_attributes

  def initialize(attrs = {})
    @attributes = HashWithIndifferentAccess.new(attrs || {})
    @data_attributes = (attrs["dataset"] || {}).each_with_object(HashWithIndifferentAccess.new) { |(key, value), memo|
      memo[key.delete_prefix("data-")] = value
    }.freeze

    super attributes.merge(attributes.transform_keys(&:underscore))
  end

  def dataset
    @dataset ||= OpenStruct.new(data_attributes.merge(data_attributes.transform_keys(&:underscore)))
  end
end
