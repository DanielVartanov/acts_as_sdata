def xml_document
  Nokogiri::XML(response.body.to_s)
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
  xml_document.xpath(xpath).to_xml.should == Nokogiri::XML(xml).root.to_xml
end