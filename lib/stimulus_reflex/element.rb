# frozen_string_literal: true

class StimulusReflex::Element < OpenStruct
  attr_reader :attributes, :data_attributes

  def initialize(data = {})
    @attributes = HashWithIndifferentAccess.new(data["attrs"] || {})
    @data_attributes = (data["dataset"] || {}).select { |key, _| key.start_with? "data-" }
    super @attributes.merge(@data_attributes).transform_keys(&:underscore)
    @data_attributes.transform_keys! { |key| key.delete_prefix "data-" }
  end

  def dataset
    @dataset ||= OpenStruct.new(data_attributes.merge(data_attributes.transform_keys(&:underscore)))
  end
end
