# frozen_string_literal: true

# forzen_string_literal: true

module StimulusReflex
  module HTML
    class DocumentFragment < Document
      SELF_CLOSING_TAGS = %w[area base br col embed hr img input link meta param source track wbr].freeze

      def parse_html(html)
        html_string = fix_self_closing_tags(html.to_s)
        Nokogiri.parse(html_string)
      end

      def fix_self_closing_tags(html_string)
        html_string.gsub(/(<(#{SELF_CLOSING_TAGS.join("|")})(\s+[^>]*[^>\/])*\s*)(?:>)/, '\1/>')
          .gsub(/<\/(#{SELF_CLOSING_TAGS.join("|")})\s*>/, "")
      end
    end
  end
end
