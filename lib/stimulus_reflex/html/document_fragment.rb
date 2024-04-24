# frozen_string_literal: true

module StimulusReflex
  module HTML
    class DocumentFragment < Document
      def parsing_class
        Nokogiri
      end
    end
  end
end
