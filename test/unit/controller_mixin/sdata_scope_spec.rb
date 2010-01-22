require File.join(File.dirname(__FILE__), '..', 'spec_helper')

include SData

describe ControllerMixin, "#sdata_scope" do
  describe "given a controller which acts as sdata" do
    before :all do
      Base = Class.new(ActionController::Base)
      Base.extend ControllerMixin
      Base.__send__ :define_method, :sdata_scope, lambda { super }
      
      Model = Class.new
      Base.acts_as_sdata  :model => Model
    end

    before :each do
      @controller = Base.new
    end
    
    describe "when params contain :predicate key" do
      before :each do
        @controller.stub! :params => { :predicate => 'born_at gt 1900' }
      end

      it "should apply to SData::Predicate for conditions" do
        Model.should_receive(:all).with :conditions => ['"born_at" > ?', '1900']
        @controller.send :sdata_scope
      end
    end

    describe "when params do not contain :predicate key" do
      before :each do
        @controller.stub! :params => {}
      end

      it "should return all entity records" do
        Model.should_receive(:all).with({})
        @controller.send :sdata_scope
      end
    end
  end
end