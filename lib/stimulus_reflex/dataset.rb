# frozen_string_literal: true

require "stimulus_reflex/utils/attribute_builder"

class StimulusReflex::Dataset < OpenStruct
  include StimulusReflex::AttributeBuilder

  def initialize(datasets)
    super datasets
  end

  def signed
    @signed ||= ->(accessor) { GlobalID::Locator.locate_signed(self[accessor]) }
  end

  def unsigned
    @unsigned ||= ->(accessor) { GlobalID::Locator.locate(self[accessor]) }
  end

  def truthy?
    @truthy ||= ->(accessor) { ActiveModel::Type::Boolean.new.cast(self[accessor]) || self[accessor].blank? }
  end

  def numeric
    @numeric ||= ->(accessor) { Float(self[accessor]) }
  end
end
