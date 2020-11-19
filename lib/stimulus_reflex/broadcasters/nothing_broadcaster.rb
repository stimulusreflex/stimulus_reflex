# frozen_string_literal: true

module StimulusReflex
  class NothingBroadcaster < Broadcaster
    def broadcast(_, data)
      broadcast_message subject: "nothing", data: data
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
