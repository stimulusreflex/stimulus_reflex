# frozen_string_literal: true

module StimulusReflex
  class NothingBroadcaster < Broadcaster
    def broadcast(_, data)
      operations << ["document", :dispatch_event]
      cable_ready.dispatch_event(
        name: "stimulus-reflex:morph-nothing",
        selector: nil,
        payload: payload,
        stimulus_reflex: data.merge(morph: to_sym)
      ).broadcast
    end

    def nothing?
      true
    end

    def to_sym
      :nothing
    end

    def to_s
      "Nothing"
    end
  end
end
