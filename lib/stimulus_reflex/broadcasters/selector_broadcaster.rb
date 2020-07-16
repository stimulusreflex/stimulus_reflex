# frozen_string_literal: true

module StimulusReflex
  class SelectorBroadcaster < Broadcaster
    def broadcast(_, data = {})
      morphs.each do |morph|
        selectors, html = morph
        updates = selectors.is_a?(Hash) ? selectors : Hash[selectors, html]
        updates.each do |selector, html|
          last = morph == morphs.last && selector == updates.keys.last
          enqueue_selector_broadcast selector, data, html, last
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

    private

    def enqueue_selector_broadcast(selector, data, html, last)
      html = html.to_s
      html = "<span>#{html}</span>" unless html.include?("<")
      fragment = Nokogiri::HTML(html)
      parent = fragment.at_css(selector)
      cable_ready[stream_name].morph(
        selector: selector,
        html: parent.present? ? parent.inner_html : fragment.to_html,
        children_only: true,
        permanent_attribute_name: permanent_attribute_name,
        stimulus_reflex: data.merge({
          last: last,
          morph_mode: "selector"
        })
      )
    end
  end
end
