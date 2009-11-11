require File.join(File.dirname(__FILE__), '..', '..', '..', 'spec_helper')

include SData

describe ControllerMixin, ".acts_as_sdata" do
  describe "given an ActionController::Base class extended by ControllerMixin" do
    before :all do
      Base = Class.new ActionController::Base
      Base.extend ControllerMixin
    end

    before :each do
      @options = { :model => Class.new }
      Base.acts_as_sdata @options
    end

    it "should make passed options available for class" do
      Base.sdata_options.should == @options
    end

    it "should make passed options available for instances" do
      Base.new.sdata_options.should == @options
    end

    it "should include instance methods" do
      Base.new.should respond_to(:build_sdata_feed)
    end
  end
end