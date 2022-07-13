# frozen_string_literal: true

module StimulusReflex
  class Fragment
    delegate :to_html, to: :@fragment

    def initialize(html)
      @fragment = Nokogiri::HTML.fragment(html.to_s)
      @matches = {
        "body" => Match.new(@fragment)
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

      def to_html
        element&.inner_html(save_with: Broadcaster::DEFAULT_HTML_WITHOUT_FORMAT)
      end
    end
  end
end
