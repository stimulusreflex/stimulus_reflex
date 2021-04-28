class StimulusReflex::ReflexData
  attr_reader :data

  def initialize(data)
    @data = data
  end

  def reflex_name
    reflex_name = target.split("#").first
    reflex_name = reflex_name.camelize
    reflex_name.end_with?("Reflex") ? reflex_name : "#{reflex_name}Reflex"
  end

  def selectors
    selectors = (data["selectors"] || []).select(&:present?)
    selectors = data["selectors"] = ["body"] if selectors.blank?
    selectors
  end

  def target
    data["target"].to_s
  end

  def method_name
    target.split("#").second
  end

  def arguments
    (data["args"] || []).map { |arg| object_with_indifferent_access arg } || []
  end

  def url
    data["url"].to_s
  end

  def element
    StimulusReflex::Element.new(data)
  end

  def permanent_attribute_name
    data["permanentAttributeName"]
  end

  def form_data
    Rack::Utils.parse_nested_query(data["formData"])
  end

  def form_params
    form_data.deep_merge(data["params"] || {})
  end

  def reflex_id
    data["reflexId"]
  end

  def xpath_controller
    data["xpathController"]
  end

  def xpath_element
    data["xpathElement"]
  end

  def reflex_controller
    data["reflexController"]
  end
end
