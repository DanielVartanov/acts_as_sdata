require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')

describe SData::ControllerMixin, "#sdata_scope" do
  context "given a controller which acts as sdata and accesses a non-linked model" do
    before :all do

      Object.__send__ :remove_const, :Model if defined?(Model)
      class Model < SData::Resource
        self.baze_class = Class.new

        define_payload_map :born_at => { :baze_field => :born_at }

        acts_as_sdata
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

    context "when params contain where clause" do
      before :each do
        @controller.stub! :params => { 'where bornAt gt 1900' => nil }
      end

      it "should apply to SData::Predicate for conditions" do
        Model.should_receive(:all).with :conditions => ['"born_at" > ?', '1900']
        @controller.send :sdata_scope
      end

      context "when condition contain 'ne' relation" do
        before :each do
          @controller.stub! :params => { 'where born_at ne 1900' => nil }
        end

        it "should parse it correctly" do
          Model.should_receive(:all).with :conditions => ['"born_at" <> ?', '1900']
          @controller.send :sdata_scope
        end
      end
    end

    context "when params do not contain :predicate key" do
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
