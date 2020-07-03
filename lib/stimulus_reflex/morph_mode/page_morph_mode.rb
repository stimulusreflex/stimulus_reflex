module StimulusReflex
  class PageMorphMode < MorphMode
    def broadcast
      render_page_and_broadcast_morph reflex, selectors, data
    end

    def to_sym
      :page
    end

    def page?
      true
    end
  end
end
