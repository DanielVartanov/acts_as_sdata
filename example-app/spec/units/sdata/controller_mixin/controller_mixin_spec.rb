require File.join(File.dirname(__FILE__), '..', '..', '..', 'spec_helper')

include SData

describe ControllerMixin do
  describe "given a class which behaves like ActionController::Base" do
    before :all do
      Base = Class.new(ActionController::Base)
    end

    describe "when SData::ControllerMixin is included" do
      before :each do
        Base.__send__ :include, ControllerMixin
      end

      it "class should respond to .acts_as_sdata" do
        Base.should respond_to(:acts_as_sdata)
        Base.new.should_not respond_to(:acts_as_sdata)
      end

      it "instance should respond to methods of ControllerMixin::InstanceMethods" do
        Base.new.should respond_to(:build_sdata_feed)
        Base.should_not respond_to(:build_sdata_feed)
      end
    end
  end
end
