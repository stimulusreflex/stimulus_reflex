# frozen_string_literal: true

module StimulusReflex
  module HTML
    class Part
      DEFAULT_HTML_WITHOUT_FORMAT = Nokogiri::XML::Node::SaveOptions::DEFAULT_HTML & ~Nokogiri::XML::Node::SaveOptions::FORMAT

      delegate :element, to: :@fragment

      def to_html
        @fragment.to_html(save_with: DEFAULT_HTML_WITHOUT_FORMAT)
      end

      def outer_html
        @fragment.to_html(save_with: DEFAULT_HTML_WITHOUT_FORMAT)
      end

      def inner_html
        @fragment.inner_html(save_with: DEFAULT_HTML_WITHOUT_FORMAT)
      end

      def nokogiri_parser(html)
        raise "not implemented"
      end

      def initialize(html)
        @fragment = nokogiri_parser(html.to_s)
        @matches = {
          "body" => Match.new(@fragment.at_css("body"))
        }
      end

      def empty?
        @fragment.content.empty?
      end

      def match(selector)
        @matches[selector] ||= Match.new(@fragment.at_css(selector))
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
