module StimulusReflex
  class NothingMorphMode < MorphMode
    def broadcast(reflex, selectors, data)
      broadcast_message subject: "nothing", data: data
    end

    def to_sym
      :nothing
    end

    def nothing?
      true
    end
  end
end
