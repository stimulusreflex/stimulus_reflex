module StimulusReflex
  module Transport
    class CableReadyAdapter < BaseAdapter
      include CableReady::Broadcaster

      def initialize(channel)
        @channel = channel
      end

      def transmit_morphs(selectors, data, html)
        super

        safe_selectors.each do |selector|
          cable_ready[@channel.stream_name].morph(
            selector: selector,
            html: document.css(selector).inner_html,
            children_only: true,
            permanent_attribute_name: data["permanent_attribute_name"],
            stimulus_reflex: data.merge(last: selector == safe_selectors.last)
          )
        end
        cable_ready.broadcast
      end

      def transmit_errors(message, data = {})
        super

        cable_ready[@channel.stream_name].dispatch_event(
          name: "stimulus-reflex:500",
          detail: {stimulus_reflex: data.merge(error: message)}
        )
        cable_ready.broadcast
      end
    end
  end
end
