require File.join(File.dirname(__FILE__), '..', '..', '..', 'spec_helper')

include SData

describe ActiveRecordMixin do
  describe "given a class extended by ActiveRecordExtentions" do
    before :all do
      Base = Class.new
      Base.extend ActiveRecordMixin
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

      it "should include instance methods" do
        Base.new.should respond_to(:to_atom)
      end

      describe "when :instance_id is passed" do
        it "should check if passed attribute is unique" do
          pending "Not implemented yet"
        end
      end
    end
  end
end