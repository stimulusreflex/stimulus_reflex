module StimulusReflex
  class MorphMode
    include StimulusReflex::Broadcaster

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
