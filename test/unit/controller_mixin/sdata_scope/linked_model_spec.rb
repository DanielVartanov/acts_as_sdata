require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')

describe SData::ControllerMixin, "#sdata_scope" do
  context "given a controller which acts as sdata and accesses a linked model" do
    context "being configured without user scoping" do
      before :all do
        BaseModel = Class.new(ActiveRecord::Base)

        Object.__send__ :remove_const, :Model if defined?(Model)
        class Model < SData::VirtualBase
          self.baze_class = BaseModel

          define_payload_map :born_at => { :baze_field => :born_at }

          acts_as_sdata :link => :simply_guid
        end

        class Controller < ActionController::Base
          extend SData::ControllerMixin

          acts_as_sdata  :model => Model, :feed =>
                           {:author => 'Billing Boss',
                            :path => '/trading_accounts',
                            :title => 'Billing Boss | Trading Accounts',
                            :default_items_per_page => 10,
                            :maximum_items_per_page => 100}
        end
      end

      before :each do
        @controller = Controller.new
        Model.stub! :all => []
      end

      context "when params contain :condition key and where clause" do
        before :each do
          @controller.stub! :params => { 'where born_at gt 1900' => nil, :condition => '$linked' }
        end

        it "should apply to SData::Predicate for conditions and append requirement for simply guid" do
          Model.should_receive(:all).with :conditions => ['"born_at" > ? and id IN (SELECT bb_model_id FROM sd_uuids WHERE bb_model_type = \'BaseModel\' and sd_class = \'Model\')', '1900']
          @controller.send :sdata_scope
        end
      end

      context "when params contain :condition key but does not contain where clause" do
        before :each do
          @controller.stub! :params => {:condition => '$linked'}
        end

        it "should return all entity records with simply guid" do
          Model.should_receive(:all).with :conditions => ['id IN (SELECT bb_model_id FROM sd_uuids WHERE bb_model_type = \'BaseModel\' and sd_class = \'Model\')']
          @controller.send :sdata_scope
        end
      end
    end
  end
end