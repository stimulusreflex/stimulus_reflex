# frozen_string_literal: true

module StimulusReflex
  class PageBroadcaster < Broadcaster
    def broadcast(selectors, data)
      reflex.controller.process reflex.url_params[:action]
      page_html = reflex.controller.response.body

      return unless page_html.present?

      document = Nokogiri::HTML(page_html)
      selectors = selectors.select { |s| document.css(s).present? }
      updates = selectors.each_with_object({}) { |selector, memo|
        html = document.css(selector).inner_html
        cable_ready[stream_name].morph(
          selector: selector,
          html: html,
          children_only: true,
          permanent_attribute_name: permanent_attribute_name,
          stimulus_reflex: data.merge({
            last: selector == selectors.last,
            broadast_type: to_sym
          })
        )
        memo[selector] = html
      }
      cable_ready.broadcast
      broadcast_message subject: "success", data: data.merge(updates: updates)
    end

    def to_sym
      :page
    end

    def page?
      true
    end
  end
end
