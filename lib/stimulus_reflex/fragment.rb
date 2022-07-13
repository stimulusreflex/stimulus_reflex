# frozen_string_literal: true

module StimulusReflex
  class Fragment
    delegate :to_html, to: :"@fragment"

    def initialize(html)
      @fragment = Nokogiri::HTML.fragment(html.to_s)
      @matches = {
        "body" => @fragment
      }
    end

    def empty?
      @fragment.content.empty?
    end

    def match(selector)
      @matches[selector] ||= @fragment.at_css(selector)
    end
  end
end
