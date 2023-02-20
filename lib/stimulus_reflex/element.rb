# frozen_string_literal: true

require "stimulus_reflex/dataset"
require "stimulus_reflex/utils/attribute_builder"

class StimulusReflex::Element < OpenStruct
  include StimulusReflex::AttributeBuilder

  attr_reader :attrs, :dataset, :selector
  attr_accessor :cable_ready

  alias_method :data_attributes, :dataset

  delegate :signed, :unsigned, :numeric, :boolean, :data_attrs, to: :dataset

  def initialize(data = {}, selector: nil)
    @selector = selector

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

  def update
    cable_ready.broadcast
  end

  def method_missing(method_name, *arguments, &block)
    if cable_ready.respond_to?(method_name)
      xpath = selector ? selector.starts_with?("//") : false
      args = {selector: selector, xpath: xpath}.merge(arguments.first.to_h)

      cable_ready.send(method_name.to_sym, args)

      cable_ready
    else
      super
    end
  end

  def respond_to_missing?(method_name)
    cable_ready.respond_to?(method_name) || super
  end
end
