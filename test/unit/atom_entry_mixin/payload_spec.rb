require File.join(File.dirname(__FILE__), '..', 'spec_helper')

include SData

describe AtomEntryMixin, "#payload" do
  context "given an Atom::Entry with AtomEntryMixin included" do
    before :each do
      Atom::Entry.send :include, AtomEntryMixin      
    end

    it "should respond to payload getter and setter" do
      @entry = Atom::Entry.new
      @entry.should respond_to(:payload)
      @entry.should respond_to(:payload=)
    end

    context "when payload is assigned" do
      before :each do
        @entry = Atom::Entry.new
        @entry.payload = Payload.new(TradingAccount.new(43660, "88815929-A503-4fcb-B5CC-F1BB8ECFC874"))
      end

      it "should be represented in XML" do
        puts @entry.to_xml.should
        @entry.to_xml.should contain(<<XML
<payload xmlns:sdata="http://schemas.sage.com/sdata/2008/1">
  <sdata:tradingAccount url="http://www.billingboss.com/myApp/myContract/-/tradingAccounts!43660" uuid="88815929-A503-4fcb-B5CC-F1BB8ECFC874"/>
</payload>
XML
)
      end
    end

    context "when Atom::Entry is loaded from XML" do
      it "should assign payload"
    end
  end
end