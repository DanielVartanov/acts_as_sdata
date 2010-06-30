module Nokogiri::ElementExtensions
  def name_with_ns
    "#{self.namespace.prefix}:#{self.name}"
  end

  def attributes_with_ns
    returning Hash.new do |hash|
      self.attributes.each_pair do |attr_name, attr|
        key_with_ns = "#{attr.namespace.prefix}:#{attr.name}"
        hash[key_with_ns] = attr.value
      end
    end
  end
end

Nokogiri::XML::Element.__send__ :include, Nokogiri::ElementExtensions

def parse_xml(xml)
  options = Nokogiri::XML::ParseOptions::DEFAULT_XML | Nokogiri::XML::ParseOptions::NOBLANKS
  Nokogiri::XML(xml, nil, nil, options)
end