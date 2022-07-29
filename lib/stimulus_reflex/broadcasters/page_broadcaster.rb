# frozen_string_literal: true

module StimulusReflex
  class PageBroadcaster < Broadcaster
    def broadcast(selectors, data)
      reflex.controller.process reflex.params[:action]
      fragment = StimulusReflex::Fragment.new(reflex.controller.response.body)

      return if fragment.empty?

      selectors = selectors.select { |s| fragment.match(s).present? }
      selectors.each do |selector|
        operations << [selector, StimulusReflex.config.morph_operation]
        html = fragment.match(selector).to_html
        cable_ready.send StimulusReflex.config.morph_operation, {
          selector: selector,
          html: html,
          payload: payload,
          children_only: true,
          permanent_attribute_name: permanent_attribute_name,
          stimulus_reflex: data.merge(morph: to_sym)
        }
      end
      cable_ready.broadcast
    end

    def to_sym
      :page
    end

    def page?
      true
    end

    def to_s
      "Page"
    end
  end
end
