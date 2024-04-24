# frozen_string_literal: true

module StimulusReflex
  module HTML
    class DocumentFragment < Document
      def parsing_class
        Nokogiri::HTML5::Inference
      end

      def document_element
        @document
      end
    end
  end
end
