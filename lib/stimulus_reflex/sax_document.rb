class StimulusReflex::SaxDocument < Nokogiri::XML::SAX::Document
  attr_reader :body

  def initialize
    @buffer = StringIO.new
  end

  def start_element(name, attrs = [])
    @started ||= /body/i.match?(name)
    return unless @started
    @buffer << if attrs.blank?
      "<#{name}>"
    else
      "<#{name} #{attrs.map { |key, val| val ? "#{key}=\"#{val}\"" : key }.join " "}>"
    end
  end

  def characters(string)
    return unless @started
    @buffer << string.squish
  end

  def end_element(name)
    return unless @started
    @buffer << "</#{name}>"
    @body = @buffer.string.to_s if /body/i.match?(name)
  end
end
