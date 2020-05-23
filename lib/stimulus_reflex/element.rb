# frozen_string_literal: true

class StimulusReflex::Element
  attr_reader :attributes
  attr_reader :dataset

  delegate :[], to: :"@attributes"

  def initialize(attrs = {})
    @attributes = HashWithIndifferentAccess.new(attrs["attrs"] || {}).freeze
    @dataset = (attrs["dataset"] || {}).each_with_object(HashWithIndifferentAccess.new) { |(key, value), memo|
      memo[key.delete_prefix("data-")] = value
    }.freeze
  end
end
