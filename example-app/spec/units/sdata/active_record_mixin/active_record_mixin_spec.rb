require File.join(File.dirname(__FILE__), '..', '..', '..', 'spec_helper')

include SData

describe ActiveRecordMixin do
  describe "given a class which behaves like ActiveRecord::Base" do
    before :all do
      Base = Class.new
    end

    describe "when ActiveRecordMixin is included" do
      before :each do
        Base.__send__ :include, ActiveRecordMixin
      end

      it "should define .acts_as_data class method" do
        Base.should respond_to(:acts_as_sdata)
        Base.new.should_not respond_to(:acts_as_sdata)
      end

      it "should copy instance methods" do
        Base.new.should respond_to(:to_atom)
        Base.should_not respond_to(:to_atom)
      end
    end
  end
end