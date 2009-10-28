require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')

include SData

describe ActiveRecordExtentions do
  describe "given a class which behaves like ActiveRecord::Base" do
    before :all do
      Base = Class.new
    end

    describe "when extended by a class" do
      before :each do
        Base.extend(ActiveRecordExtentions)
      end

      it "should define .acts_as_data class method" do
        Base.should respond_to(:acts_as_sdata)
        Base.new.should_not respond_to(:acts_as_sdata)
      end

      describe "when .acts_as_sdata is called without arguments" do
        before :each do
          Base.class_eval { acts_as_sdata }
        end

        it "should define #to_atom instance method" do
          Base.new.should respond_to(:to_atom)
        end

        describe "#to_atom" do
          before :each do
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
      end

      describe "when .acts_as_sdata is called with arguments" do
        before :each do
          Base.class_eval do
            acts_as_sdata :title => lambda { "#{id}: #{name}" },
                          :summary => lambda { "#{name}" }
          end
        end

        it "should evaulate given lambda's in the correct context" do
          @model = Base.new
          @model.stub! :id => 1, :name => 'Test', :to_xml => ''

          @model.to_atom.title.should == '1: Test'
          @model.to_atom.summary.should == 'Test'
        end
      end
    end
  end
end