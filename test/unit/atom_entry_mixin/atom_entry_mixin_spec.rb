require File.join(File.dirname(__FILE__), '..', 'spec_helper')

include SData

describe "Atom extensions" do
  describe "given an extended Atom::Entry" do
    it "should respond to #to_attributes" do
      Atom::Entry.new.should respond_to(:to_attributes)
    end
  end
end
