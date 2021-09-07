# frozen_string_literal: true

module StimulusReflex::AttributeBuilder
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
