__DIR__ = File.dirname(__FILE__)
require File.join(__DIR__, '..', 'spec_helper')

include SData

describe ControllerMixin, ".has_sdata_options" do
  describe "given an ActionController::Base class extended by ControllerMixin" do
    before :all do
      Base = Class.new ActionController::Base
      Base.extend ControllerMixin
    end

    before :each do
      @options = { :model => Class.new }
      Base.has_sdataoptions @options
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
