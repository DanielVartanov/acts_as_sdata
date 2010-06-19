require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe SData::ActiveRecordExtensions::Mixin do
  describe "given a class which behaves like ActiveRecord::Base" do
    before :all do
      Base = Class.new
    end

    describe "when ActiveRecordExtensions::Mixin is included" do
      before :each do
        Base.extend SData::ActiveRecordExtensions::Mixin
      end

      it "should define .acts_as_data class method" do
        Base.should respond_to(:acts_as_sdata)
        Base.new.should_not respond_to(:acts_as_sdata)
      end
    end
  end
end