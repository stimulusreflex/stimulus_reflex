# frozen_string_literal: true

module StimulusReflex
  class PageBroadcaster < Broadcaster
    def broadcast(selectors, data)
      reflex.controller.process reflex.params[:action]
      page_html = reflex.controller.response.body

      return unless page_html.present?

      document = Nokogiri::HTML.parse(page_html)
      selectors = selectors.select { |s| document.css(s).present? }
      selectors.each do |selector|
        operations << [selector, :morph]
        html = document.css(selector).inner_html(save_with: Broadcaster::DEFAULT_HTML_WITHOUT_FORMAT)
        cable_ready.morph(
          selector: selector,
          html: html,
          payload: payload,
          children_only: true,
          permanent_attribute_name: permanent_attribute_name,
          stimulus_reflex: data.merge(morph: to_sym)
        )
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
