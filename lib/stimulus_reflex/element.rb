# frozen_string_literal: true

require "stimulus_reflex/dataset"
require "stimulus_reflex/utils/attribute_builder"

class StimulusReflex::Element < OpenStruct
  include StimulusReflex::AttributeBuilder

  attr_reader :attrs, :data_attrs, :dataset

  alias_method :data_attributes, :dataset

  delegate :signed, :unsigned, :numeric, :truthy?, to: :dataset

  def initialize(data = {})
    @attrs = HashWithIndifferentAccess.new(data["attrs"] || {})
    datasets = data["dataset"] || {}
    regular_dataset = datasets["dataset"] || {}
    @data_attrs = build_data_attrs(regular_dataset, datasets["datasetAll"] || {})
    all_attributes = @attrs.merge(@data_attrs)
    super build_underscored(all_attributes)
    @data_attrs.transform_keys! { |key| key.delete_prefix "data-" }

    @dataset = StimulusReflex::Dataset.new(build_underscored(data_attrs))
  end

  def attributes
    @attributes ||= OpenStruct.new(build_underscored(attrs))
  end
end
