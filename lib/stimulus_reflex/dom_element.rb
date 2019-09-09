# frozen_string_literal: true

class StimulusReflex::DomElement
  attr_reader :attributes

  delegate :[], to: :"@attributes"

  def initialize(attrs = {})
    @attributes = HashWithIndifferentAccess.new(attrs || {}).freeze
  end

  def dataset
    @dataset ||= attributes.each_with_object(HashWithIndifferentAccess.new) { |(key, value), memo|
      next unless key.start_with?("data-")
      memo[key.delete_prefix("data-")] = value
    }.freeze
  end
end
