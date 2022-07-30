# frozen_string_literal: true

module StimulusReflex
  module HTML
    class Fragment < Part
      def nokogiri_parser(html)
        Nokogiri::HTML.fragment(html)
      end
    end
  end
end
