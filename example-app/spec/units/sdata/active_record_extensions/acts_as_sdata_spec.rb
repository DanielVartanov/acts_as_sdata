require File.join(File.dirname(__FILE__), '..', '..', '..', 'spec_helper')

include SData

describe ActiveRecordExtentions do
  describe "given a class extended by ActiveRecordExtentions" do
    before :all do
      Base = Class.new
      Base.extend(ActiveRecordExtentions)
    end

    describe ".acts_as_sdata" do
      before :each do
        @options = { :title => lambda { "#{id}: #{name}" },
                     :summary => lambda { "#{name}" } }
        
        options = @options
        Base.class_eval do
          acts_as_sdata options
        end
      end

      it "should save passed options to variable accessible by class" do
        Base.sdata_options.should == @options
      end

      it "should save passed options to variable accessible by instances" do
        Base.new.sdata_options.should == @options        
      end

      it "should define #to_atom instance method" do
        Base.new.should respond_to(:to_atom)
      end
    end
  end
end