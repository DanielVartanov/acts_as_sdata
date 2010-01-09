require File.join(File.dirname(__FILE__), '..', 'spec_helper')

include SData

describe AtomEntryMixin do
  describe "given a class which behaves like Atom::Entry" do
    before :each do
      @entry_class = Atom::Entry.dup
    end

    describe "when AtomEntryMixin is included" do
      before :each do
        @entry_class.send :include, AtomEntryMixin
      end

      it "should respond to #to_attributes" do
        @entry_class.new.should respond_to(:to_attributes)
      end
    end
  end
end
