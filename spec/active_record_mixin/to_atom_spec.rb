require File.join(File.dirname(__FILE__), '..', 'spec_helper')
                                                          
include SData

describe ActiveRecordMixin, "#to_atom" do
  describe "given a class extended by ActiveRecordExtentions" do
    before :all do
      Base = Class.new
      Base.extend ActiveRecordMixin
    end

    describe "when .acts_as_sdata is called without arguments" do
      before :each do
        Base.class_eval { acts_as_sdata }
        @model = Base.new
        @model.stub! :id => 1
      end

      it "should return an Atom::Entry instance" do
        @model.to_atom.should be_kind_of(Atom::Entry)
      end

      it "should assign model name to Atom::Entry#summary" do
        @model.to_atom.summary.should == 'Base'
      end

      it "should assign model name and id to Atom::Entry#title" do
        @model.to_atom.title.should == 'Base(1)'
      end

      it "should assign Atom::Entry#updated" do
        pending
      end

      it "should assign Atom::Entry#links" do
        pending
      end

      it "should assign Atom::Entry::id" do
        pending
      end
    end

    describe "when .acts_as_sdata is called with arguments" do
      before :each do
        Base.class_eval do
          acts_as_sdata :title => lambda { "#{id}: #{name}" },
                        :summary => lambda { "#{name}" }
        end

        @model = Base.new
        @model.stub! :id => 1, :name => 'Test', :to_xml => ''
      end

      it "should evaulate given lambda's in the correct context" do
        @model.to_atom.title.should == '1: Test'
        @model.to_atom.summary.should == 'Test'
      end
    end
  end
end