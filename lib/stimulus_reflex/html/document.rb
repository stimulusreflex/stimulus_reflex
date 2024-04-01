# frozen_string_literal: true

module StimulusReflex
  module HTML
    class Document
      DEFAULT_HTML_WITHOUT_FORMAT = Nokogiri::XML::Node::SaveOptions::DEFAULT_HTML & ~Nokogiri::XML::Node::SaveOptions::FORMAT

      def initialize(html)
        @document = parsing_class.parse(html.to_s)
        @matches = {}
      end

      def empty?
        @document.content.empty?
      end

      def parsing_class
        Nokogiri::HTML5::Document
      end

      def match(selector)
        @matches[selector] ||= Match.new(@document.at_css(selector))
      end

      Match = Struct.new(:element) do
        delegate :present?, to: :element

        def outer_html
          element&.to_html(save_with: DEFAULT_HTML_WITHOUT_FORMAT)
        end

        def to_html
          element&.to_html(save_with: DEFAULT_HTML_WITHOUT_FORMAT)
        end

        def inner_html
          element&.inner_html(save_with: DEFAULT_HTML_WITHOUT_FORMAT)
        end
      end
    end
  end
end
