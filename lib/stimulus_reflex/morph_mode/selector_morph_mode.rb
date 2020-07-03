module StimulusReflex
  class SelectorMorphMode < MorphMode
    def broadcast(reflex, selectors, data)
      broadcast_message subject: "selector", data: data
    end

    def to_sym
      :selector
    end

    def selector?
      true
    end
  end
end
