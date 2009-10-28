require File.join(File.dirname(__FILE__), '..', '..', '..', 'spec_helper')

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
    end
  end
end