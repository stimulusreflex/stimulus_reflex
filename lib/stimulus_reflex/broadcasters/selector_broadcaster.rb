# frozen_string_literal: true

module StimulusReflex
  class SelectorBroadcaster < Broadcaster
    def broadcast(_, data = {})
      morphs.each do |morph|
        selectors, html = morph
        updates = selectors.is_a?(Hash) ? selectors : Hash[selectors, html]
        updates.each do |selector, html|
          html = html.to_s
          fragment = Nokogiri::HTML.fragment(html)
          match = fragment.at_css(selector)
          if match.present?
            cable_ready[stream_name].morph(
              selector: selector,
              html: match.inner_html,
              children_only: true,
              permanent_attribute_name: permanent_attribute_name,
              stimulus_reflex: data.merge({
                broadcaster: to_sym
              })
            )
          else
            cable_ready[stream_name].inner_html(
              selector: selector,
              html: fragment.to_html,
              stimulus_reflex: data.merge({
                broadcaster: to_sym
              })
            )
          end
        end
      end

      cable_ready.broadcast
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
