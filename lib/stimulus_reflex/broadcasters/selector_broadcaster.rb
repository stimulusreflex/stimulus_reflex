# frozen_string_literal: true

module StimulusReflex
  class SelectorBroadcaster < Broadcaster
    def broadcast(_, data = {})
      all_updates = {}
      morphs.each do |morph|
        selectors, html = morph
        updates = selectors.is_a?(Hash) ? selectors : Hash[selectors, html]
        updates.each do |selector, html|
          last = morph == morphs.last && selector == updates.keys.last
          html = html.to_s
          fragment = Nokogiri::HTML.fragment(html)
          match = fragment.at_css(selector)
          if match
            cable_ready[stream_name].morph(
              selector: selector,
              html: element.inner_html,
              children_only: true,
              permanent_attribute_name: permanent_attribute_name,
              stimulus_reflex: data.merge({
                last: last,
                broadast_type: to_sym
              })
            )
          else
            cable_ready[stream_name].inner_html(
              selector: selector,
              html: fragment.to_html,
              stimulus_reflex: data.merge({
                last: last,
                broadast_type: to_sym
              })
            )
          end
          all_updates[selector] = html.truncate(80)
        end
      end

      cable_ready.broadcast
      broadcast_message subject: "success", data: data.merge(updates: all_updates)
      morphs.clear
    end

    def morphs
      @morphs ||= []
    end

    def to_sym
      :selector
    end

    def selector?
      true
    end
  end
end
