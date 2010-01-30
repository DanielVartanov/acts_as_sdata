def parse_xml(xml_string)
  parsing_options = Nokogiri::XML::ParseOptions::DEFAULT_XML | Nokogiri::XML::ParseOptions::NOBLANKS
  Nokogiri::XML(xml_string, nil, nil, parsing_options)
end

def xml_document
  parse_xml(response.body.to_s)
end

Then /^XML document should have XPath (.+)$/ do |xpath|
  xml_document.root.children.should have_xpath(xpath)
end

Then /^XML document should not have XPath (.*)$/ do |xpath|
  xml_document.root.children.should_not have_xpath(xpath)
end

Then /^response should contain XML document$/ do
  Then %{response content type should be "application/xml; charset=utf-8"}
  xml_document.root.should_not be_nil
end

Then /^XML document should contain the following at XPath (.+):$/ do |xpath, xml|
  Then %{XML document should have XPath #{xpath}}

  expected_xml_document = parse_xml(xml)
  xml_document.xpath(xpath).to_xml.should == expected_xml_document.root.to_xml
end