# frozen_string_literal: true

require "stimulus_reflex/utils/attribute_builder"

class StimulusReflex::Dataset < OpenStruct
  include StimulusReflex::AttributeBuilder

  attr_accessor :attrs, :data_attrs

  def initialize(data = {})
    datasets = data["dataset"] || {}
    regular_dataset = datasets["dataset"] || {}
    @attrs = build_data_attrs(regular_dataset, datasets["datasetAll"] || {})
    @data_attrs = @attrs.transform_keys { |key| key.delete_prefix "data-" }

    super build_underscored(@data_attrs)
  end

  def signed
    @signed ||= ->(accessor) { GlobalID::Locator.locate_signed(self[accessor]) }
  end

  def unsigned
    @unsigned ||= ->(accessor) { GlobalID::Locator.locate(self[accessor]) }
  end

  def boolean
    @boolean ||= ->(accessor) { cast_boolean(self[accessor]) || self[accessor].blank? }
  end

  def numeric
    @numeric ||= ->(accessor) { Float(self[accessor]) }
  end

  private

  def cast_boolean(value)
    ((value == "") ? nil : !false_values.include?(value)) unless value.nil?
  end

  def false_values
    @false_values ||= [false, 0, "0", "f", "F", "false", "FALSE", "off", "OFF"].to_set
  end
end
