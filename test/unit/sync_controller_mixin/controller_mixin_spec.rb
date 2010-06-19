require File.join(File.dirname(__FILE__), '..', 'spec_helper')

include SData::Sync

describe ControllerMixin do
  describe "given a class which behaves like ActionController::Base" do
    before :all do
      Base = Class.new(ActionController::Base)
    end

    describe "when SData::Sync::ControllerMixin is included" do
      before :each do
        Base.extend ControllerMixin
      end

      it "class should respond to .syncs_sdata" do
        Base.should respond_to(:syncs_sdata)
        Base.new.should_not respond_to(:syncs_sdata)
      end
    end
  end
end