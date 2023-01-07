# frozen_string_literal: true

module StimulusReflex
  module HTML
    class Document
      DEFAULT_HTML_WITHOUT_FORMAT = Nokogiri::XML::Node::SaveOptions::DEFAULT_HTML & ~Nokogiri::XML::Node::SaveOptions::FORMAT

      delegate :element, to: :@document

      def outer_html
        if @document.is_a?(Nokogiri::HTML::DocumentFragment)
          @document
        else
          @document.root
        end.to_html(save_with: DEFAULT_HTML_WITHOUT_FORMAT)
      end
      alias_method :to_html, :outer_html

      def inner_html
        if @document.is_a?(Nokogiri::HTML::DocumentFragment)
          # `inner_html` on a DocumentFragment returns the outer HTML tag, so we need to strip it out manually.
          # There might be a cleaner way to do this?
          @document.inner_html(save_with: DEFAULT_HTML_WITHOUT_FORMAT).sub(/^<([^>]*)>/, "").sub(/<\/[^>]*>$/, "")
        else
          @document.root.inner_html(save_with: DEFAULT_HTML_WITHOUT_FORMAT)
        end
      end

      def initialize(html)
        @initial_html = html.to_s
        @document = parsing_class.parse(@initial_html)
        @matches = {
          "body" => Match.new(@document.at_css("body"))
        }
      end

      def empty?
        @document.content.empty?
      end

      # This is an imperfect solution to the problem of parsing HTML that is not technically well-formed.
      # For example, "<tr></tr>" by itself is invalid, because the HTML spec requires a <table> element.
      # To work around this, we detect if the HTML string starts and ends with a tag that, by itself, would
      # be invalid. If it is the case, we use Nokogiri::HTML::DocumentFragment document parser instead of
      # Nokogiri::HTML5::Document. The former will not strip out the invalid tags from the output.
      def relaxed_parsing?
        return @relaxed_parsing if defined?(@relaxed_parsing)

        tags = %w[tr td th thead tbody]
        @relaxed_parsing ||= @initial_html&.match?(/^\s*<(#{tags.join("|")})/i) && @initial_html&.match?(/<\s*\/\s*(#{tags.join("|")})\s*>$/i)
      end

      def parsing_class
        relaxed_parsing? ? Nokogiri::HTML::DocumentFragment : Nokogiri::HTML5::Document
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
