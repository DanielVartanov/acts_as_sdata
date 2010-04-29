require File.join(File.dirname(__FILE__), '..', 'spec_helper')

include SData

describe ControllerMixin, "#sdata_scope" do
  Model = Class.new
  Base = Class.new(ActionController::Base)
  describe "given a controller which acts as sdata and accesses a non-linked model" do
    before :all do

      Model.stub! :all => [Model.new, Model.new]

      Base.extend ControllerMixin

      Base.__send__ :define_method, :sdata_scope, lambda { super }
      
      
      Base.acts_as_sdata  :model => Model, :feed => 
                 {:author => 'Billing Boss',
                  :path => '/trading_accounts',
                  :title => 'Billing Boss | Trading Accounts',
                  :default_items_per_page => 10,
                  :maximum_items_per_page => 100}
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
  
  describe "given a controller which acts as sdata and accesses a linked model" do
    before :all do

      Model.stub! :all => [Model.new, Model.new]
      Model.stub! :sdata_options => {:link => :simply_guid}

      Base.extend ControllerMixin
  
      Base.__send__ :define_method, :sdata_scope, lambda { super }
    end
    describe "being configured without user scoping" do
      before :all do
        
        Base.acts_as_sdata  :model => Model, :feed => 
                   {:author => 'Billing Boss',
                    :path => '/trading_accounts',
                    :title => 'Billing Boss | Trading Accounts',
                    :default_items_per_page => 10,
                    :maximum_items_per_page => 100}
      end
  
      before :each do
        @controller = Base.new
      end
      
      describe "when params contain :condition key and :predicate key" do
        before :each do
          @controller.stub! :params => { :predicate => 'born_at gt 1900', :condition => 'linked' }
        end
  
        it "should apply to SData::Predicate for conditions and append requirement for simply guid" do
          Model.should_receive(:all).with :conditions => ['"born_at" > ? and simply_guid is not null', '1900']
          @controller.send :sdata_scope
        end
      end
  
      describe "when params contain :condition key but do not contain :predicate key" do
        before :each do
          @controller.stub! :params => {:condition => 'linked'}
        end
  
        it "should return all entity records with simply guid" do
          Model.should_receive(:all).with :conditions => ['simply_guid is not null']
          @controller.send :sdata_scope
        end
      end
    end

    describe "being configured with user scoping" do
      before :all do
        Base.acts_as_sdata  :model => Model, :feed => 
                   {:author => 'Billing Boss',
                    :path => '/trading_accounts',
                    :title => 'Billing Boss | Trading Accounts',
                    :default_items_per_page => 10,
                    :maximum_items_per_page => 100},
                    :scoping => [{:attribute => :created_by_id, 
                                  :object    => :current_user,
                                  :key       => :id}]
        end
        @user = User.new.populate_defaults
      before :each do
        @controller = Base.new
      end
      describe "with no other params" do
        before :each do
          @controller.stub! :params => {}
          @controller.stub! :current_user => @user
        end  
        it "should return all entity records created_by scope" do
          Model.should_receive(:all).with :conditions => ['created_by_id = ?', "#{@user.id}"]
          @controller.send :sdata_scope
        end
      end
      describe "with condition and predicate" do
        before :each do
          @controller.stub! :params => { :predicate => 'born_at gt 1900', :condition => 'linked' }
          @controller.stub! :current_user => @user
        end  
        it "should return all entity records with created_by, predicate, and link scope" do
          Model.should_receive(:all).with :conditions => ['"born_at" > ? and created_by_id = ? and simply_guid is not null', '1900', @user.id.to_s]
          @controller.send :sdata_scope
        end
      end
    end
  end
end