module StimulusReflex
  module Transport
    class MessageBusAdapter < BaseAdapter
      def initialize(request, identifier)
        @request = request
        @identifier = identifier
      end

      def env
        @request.env
      end

      def transmit_morphs(selectors, data, html)
        super

        safe_selectors.each do |selector|
          # MessageBus.publish "/channel", "foo"
          operations = {
            morph: [{ 
              
              selector: selector,
              html: document.css(selector).inner_html,
              children_only: true,
              permanent_attribute_name: data["permanent_attribute_name"],
              stimulus_reflex: data.merge(last: selector == safe_selectors.last)
            }]
          }
          operations.deep_transform_keys! { |key| key.to_s.camelize(:lower) }
          MessageBus.publish "/channel", {
                               operations: operations 
                             }.to_json
        end
      end
    end
  end
end
