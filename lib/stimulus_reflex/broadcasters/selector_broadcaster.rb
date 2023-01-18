# frozen_string_literal: true

module StimulusReflex
  class SelectorBroadcaster < Broadcaster
    def broadcast(_, data = {})
      morphs.each do |morph|
        selectors, html = morph
        updates = create_update_collection(selectors, html)
        updates.each do |update|
          document = StimulusReflex::HTML::DocumentFragment.new(update.html)
          match = document.match(update.selector)
          if match.present?
            operations << [update.selector, StimulusReflex.config.morph_operation]
            cable_ready.send StimulusReflex.config.morph_operation, {
              selector: update.selector,
              html: match.inner_html,
              payload: payload,
              children_only: true,
              permanent_attribute_name: permanent_attribute_name,
              stimulus_reflex: data.merge(morph: to_sym)
            }
          else
            operations << [update.selector, StimulusReflex.config.replace_operation]
            cable_ready.send StimulusReflex.config.replace_operation, {
              selector: update.selector,
              html: update.html.to_s,
              payload: payload,
              stimulus_reflex: data.merge(morph: to_sym)
            }
          end
        end
      end

      cable_ready.broadcast
      morphs.clear
    end

    def morphs
      @morphs ||= []
    end

    def append_morph(selectors, html)
      morphs << [selectors, html]
    end

    def to_sym
      :selector
    end

    def selector?
      true
    end

    def to_s
      "Selector"
    end

    private

    def create_update_collection(selectors, html)
      updates = selectors.is_a?(Hash) ? selectors : {selectors => html}
      updates.map do |key, value|
        StimulusReflex::Broadcasters::Update.new(key, value, reflex)
      end
    end
  end
end
