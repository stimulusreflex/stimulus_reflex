module StimulusReflex
  module Broadcaster
    include CableReady::Broadcaster

    def render_page_and_broadcast_morph(reflex, selectors, data = {})
      html = render_page(reflex)
      broadcast_morphs selectors, data, html if html.present?
    end

    def render_page(reflex)
      reflex.controller.process reflex.url_params[:action]
      reflex.controller.response.body
    end

    def broadcast_morphs(selectors, data, html)
      document = Nokogiri::HTML(html)
      selectors = selectors.select { |s| document.css(s).present? }
      selectors.each do |selector|
        cable_ready[stream_name].morph(
          selector: selector,
          html: document.css(selector).inner_html,
          children_only: true,
          permanent_attribute_name: data["permanent_attribute_name"],
          stimulus_reflex: data.merge({
            last: selector == selectors.last,
            morph_mode: "page"
          })
        )
      end
      cable_ready.broadcast
    end

    def broadcast_message(subject:, body: nil, data: {})
      message = {
        subject: subject,
        body: body
      }

      logger.error "\e[31m#{body}\e[0m" if subject == "error"

      data[:morph_mode] = "page"
      data[:server_message] = message
      data[:morph_mode] = "selector" if subject == "selector"
      data[:morph_mode] = "nothing" if subject == "nothing"

      cable_ready[stream_name].dispatch_event(
        name: "stimulus-reflex:server-message",
        detail: {stimulus_reflex: data}
      )
      cable_ready.broadcast
    end
  end
end
