# frozen_string_literal: true

class StimulusReflex::Element < OpenStruct
  attr_reader :attrs, :data_attrs, :inner_html, :text_content

  def initialize(data = {})
    @attrs = HashWithIndifferentAccess.new(data["attrs"] || {})
    @inner_html = data["inner_html"]
    @text_content = data["text_content"]

    datasets = data["dataset"] || {}
    regular_dataset = datasets["dataset"] || {}
    @data_attrs = build_data_attrs(regular_dataset, datasets["datasetAll"] || {})

    super build_underscored(all_attributes)

    @data_attrs.transform_keys! { |key| key.delete_prefix "data-" }
  end

  def signed
    @signed ||= ->(accessor) { GlobalID::Locator.locate_signed(dataset[accessor]) }
  end

  def unsigned
    @unsigned ||= ->(accessor) { GlobalID::Locator.locate(dataset[accessor]) }
  end

  def attributes
    @attributes ||= OpenStruct.new(build_underscored(attrs))
  end

  def dataset
    @dataset ||= OpenStruct.new(build_underscored(data_attrs))
  end

  alias_method :data_attributes, :dataset

  private

  def all_attributes
    @attrs.merge(@data_attrs)
  end

  def build_data_attrs(dataset, dataset_all)
    dataset_all.transform_keys! { |key| "data-#{key.delete_prefix("data-").pluralize}" }

    dataset.each { |key, value| dataset_all[key]&.prepend(value) }

    data_attrs = dataset.merge(dataset_all)

    HashWithIndifferentAccess.new(data_attrs || {})
  end

  def build_underscored(attrs)
    attrs.merge(attrs.transform_keys(&:underscore))
  end
end
