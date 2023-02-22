# frozen_string_literal: true

# forzen_string_literal: true

module StimulusReflex
  module HTML
    class DocumentFragment < Document

      HTML_TAG = /<html(( .*?(?:(?!>)[\s\S])*>)|>)/i
      HEAD_TAG = /<head(( .*?(?:(?!>)[\s\S])*>)|>)/i
      BODY_TAG = /<body(( .*?(?:(?!>)[\s\S])*>)|>)/i
      TR_TAG = /<tr(( .*?(?:(?!>)[\s\S])*>)|>)/i
      TD_TAG = /<td(( .*?(?:(?!>)[\s\S])*>)|>)/i
      TH_TAG = /<th(( .*?(?:(?!>)[\s\S])*>)|>)/i

      def document_element
        if @html =~ HTML_TAG || @html =~ HEAD_TAG || @html =~ BODY_TAG
          @document.root || @document
        elsif @html =~ TR_TAG || @html =~ TD_TAG || @html =~ TH_TAG
          @document.elements || @document
        elsif @document.children.to_a.flatten.map(&:class).include?(Nokogiri::XML::Element)
          @document.try(:root) || @document.try(:elements) || @document
        else
          @document
        end
      end

      def parsing_class
        if @html =~ HTML_TAG || @html =~ HEAD_TAG || @html =~ BODY_TAG
          Nokogiri
        elsif @html =~ TR_TAG || @html =~ TD_TAG || @html =~ TH_TAG
          Nokogiri::HTML::DocumentFragment
        else
          Nokogiri::HTML5::DocumentFragment
        end
      end
    end
  end
end
