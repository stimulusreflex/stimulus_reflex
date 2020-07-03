module StimulusReflex
  class MorphMode
    include StimulusReflex::Broadcaster

    attr_accessor :stream_name

    def page?
      false
    end

    def nothing?
      false
    end

    def selector?
      false
    end
  end
end
