require File.join(File.dirname(__FILE__), '..', '..', '..', 'spec_helper')

include SData

describe ActiveRecordMixin do
  describe "given a class which behaves like ActiveRecord::Base" do
    before :all do
      Base = Class.new
    end

    describe "when ActiveRecordMixin is included" do
      before :each do
        Base.extend ActiveRecordMixin
      end

      it "should define .acts_as_data class method" do
        Base.should respond_to(:acts_as_sdata)
        Base.new.should_not respond_to(:acts_as_sdata)
      end
    end
  end
end