# frozen_string_literal: true

class StimulusReflex::ReflexFactory
  class << self
    attr_reader :reflex_data

    def create_reflex_from_data(channel, reflex_data)
      @reflex_data = reflex_data
      reflex_class.new(channel,
        url: reflex_data.url,
        element: reflex_data.element,
        controller_element: reflex_data.controller_element,
        selectors: reflex_data.selectors,
        method_name: reflex_data.method_name,
        params: reflex_data.params,
        client_attributes: {
          id: reflex_data.id,
          tab_id: reflex_data.tab_id,
          xpath_controller: reflex_data.xpath_controller,
          xpath_element: reflex_data.xpath_element,
          reflex_controller: reflex_data.reflex_controller,
          permanent_attribute_name: reflex_data.permanent_attribute_name,
          suppress_logging: reflex_data.suppress_logging,
          version: reflex_data.version
        }
      )
    end

    def reflex_class
      reflex_data.reflex_name.constantize.tap { |klass| raise ArgumentError.new("#{reflex_name} is not a StimulusReflex::Reflex") unless is_reflex?(klass) }
    end

    def is_reflex?(klass)
      klass.ancestors.include? StimulusReflex::Reflex
    end
  end
end
