require 'nokogiri'
require 'atom'

builder = Nokogiri::XML::Builder.new do |xml|
      xml.payload(
        'xmlns:sdata' => "http://schemas.sage.com/sdata/2008/1") {
        xml['sdata'].tradingAccount :uuid => "00000-0000-0000-00000",
                           :url => "http://www.billingboss.com/myApp/myContract/-/tradingAccounts!46630"
      }
    end

#puts builder.to_xml

content = Atom::Content::Xhtml.new(builder.to_xml)

#require 'pp'
#puts content

entry = Atom::Entry.new
entry.content = content

#pp entry

#puts entry.to_xml