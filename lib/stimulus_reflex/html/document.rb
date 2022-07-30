module StimulusReflex
  module HTML
    class Document < Part
      def nokogiri_parser(html)
        Nokogiri::HTML5::Document.parse(html)
      end
    end
  end
end
