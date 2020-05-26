# frozen_string_literal: true

class StimulusReflex::Element < StimulusReflex::PermissiveOpenStruct
  attr_reader :attributes, :data_attributes

  def initialize(data = {})
    @attributes = HashWithIndifferentAccess.new(data["attrs"] || {})
    @data_attributes = HashWithIndifferentAccess.new(data["dataset"] || {})
    all_attributes = @attributes.merge(@data_attributes)
    super all_attributes.merge(all_attributes.transform_keys(&:underscore))
    @data_attributes.transform_keys! { |key| key.delete_prefix "data-" }
  end

  def dataset
    @dataset ||= begin
     StimulusReflex::PermissiveOpenStruct.new(data_attributes.merge(data_attributes.transform_keys(&:underscore)))
   end
  end
end
