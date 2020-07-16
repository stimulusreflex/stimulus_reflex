# frozen_string_literal: true

module StimulusReflex
  class PageBroadcaster < Broadcaster
    def broadcast(selectors, data)
      reflex.controller.process reflex.url_params[:action]
      html = reflex.controller.response.body

      return unless html.present?

      document = Nokogiri::HTML(html)
      selectors = selectors.select { |s| document.css(s).present? }
      selectors.each do |selector|
        cable_ready[stream_name].morph(
          selector: selector,
          html: document.css(selector).inner_html,
          children_only: true,
          permanent_attribute_name: permanent_attribute_name,
          stimulus_reflex: data.merge({
            last: selector == selectors.last,
            broadast_type: to_sym
          })
        )
      end

      cable_ready.broadcast
      broadcast_message subject: "success", data: data
    end

    def to_sym
      :page
    end

    def page?
      true
    end
  end
end
