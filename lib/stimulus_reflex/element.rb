# frozen_string_literal: true

class StimulusReflex::Element < OpenStruct
  attr_reader :attributes, :dataset

  def initialize(attrs = {})
    @attributes = HashWithIndifferentAccess.new(attrs || {})
    data_attributes = @attributes.select { |key, _| key.start_with? "data-" }
    data_attributes.transform_keys! { |key| key.delete_prefix("data-") }
    @dataset = OpenStruct.new(data_attributes.merge(data_attributes.transform_keys(&:underscore)))
    @dataset.freeze
    super @attributes.merge(@attributes.transform_keys(&:underscore))
    freeze
  end
end
