# frozen_string_literal: true

require "stimulus_reflex/dataset"
require "stimulus_reflex/utils/attribute_builder"

class StimulusReflex::Element < OpenStruct
  include StimulusReflex::AttributeBuilder

  attr_reader :attrs, :dataset

  alias_method :data_attributes, :dataset

  delegate :signed, :unsigned, :numeric, :boolean, :data_attrs, to: :dataset

  def initialize(data = {})
    @attrs = HashWithIndifferentAccess.new(data["attrs"] || {})
    @dataset = StimulusReflex::Dataset.new(data)

    all_attributes = @attrs.merge(@dataset.attrs)
    super build_underscored(all_attributes)
  end

  def attributes
    @attributes ||= OpenStruct.new(build_underscored(attrs))
  end

  def to_dom_id
    raise NoIDError.new "The element `morph` is called on must have a valid DOM ID" if id.blank?

    "##{id}"
  end
end
