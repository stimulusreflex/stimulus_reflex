module StimulusReflex
  class SelectorMorphMode < MorphMode
    def broadcast
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
