require File.join(File.dirname(__FILE__), '..', 'spec_helper')

include SData

describe AtomEntryMixin, "#to_attributes" do
  describe "given an Atom::Entry with AtomEntryMixin included" do
    before :each do
      @entry_class = Atom::Entry.dup
      @entry_class.send :include, AtomEntryMixin
    end

    describe "when model has attributes in a simple XML extension" do
      before :each do
        @entry = @entry_class.new
        @entry['http://sdata.sage.com/schemes/attributes', 'first_name'] << 'George'
        @entry['http://sdata.sage.com/schemes/attributes', 'last_name'] << 'Washington'
      end

      it "should return an ActiveRecord-friendly hash" do
        @entry.to_attributes.should == { 'first_name' => 'George', 'last_name' => 'Washington' }
      end

      describe "when some attribute has multiple values" do
        before :each do
          @entry['http://sdata.sage.com/schemes/attributes', 'initials'] << 'G.'
          @entry['http://sdata.sage.com/schemes/attributes', 'initials'] << 'GW'
        end

        it "should take the first one" do
          @entry.to_attributes['initials'].should == 'G.'
        end
      end
    end    
  end
end