require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')

describe SData::ControllerMixin, "#sdata_scope" do
  context "given a controller which acts as sdata and accesses a linked model" do
    context "being configured with user scoping" do
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
                            :maximum_items_per_page => 100},
                            :scoping => ["created_by_id = ?"]
        end
      end

      before :each do
        @user = User.new.populate_defaults
        @controller = Controller.new
        Model.stub! :all => []
      end

      context "with no other params" do
        before :each do
          @controller.stub! :params => {}
          @controller.stub! :current_user => @user
          @controller.stub! :target_user => @user
        end

        it "should return all entity records created_by scope" do
          Model.should_receive(:all).with :conditions => ['created_by_id = ?', "#{@user.id}"]
          @controller.send :sdata_scope
        end
      end

      context "with condition and where clause" do
        before :each do
          @controller.stub! :params => { 'where born_at gt 1900' => nil, :condition => '$linked' }
          @controller.stub! :current_user => @user
          @controller.stub! :target_user => @user
        end

        it "should return all entity records with created_by, predicate, and link scope" do
          BaseModel.should_receive(:find_with_deleted).with(:all, {:conditions => ['"born_at" > ? and created_by_id = ? and id IN (SELECT bb_model_id FROM sd_uuids WHERE bb_model_type = \'BaseModel\' and sd_class = \'Model\')', '1900', @user.id.to_s]}).and_return([])
          @controller.send :sdata_scope
        end
      end
    end
  end
end