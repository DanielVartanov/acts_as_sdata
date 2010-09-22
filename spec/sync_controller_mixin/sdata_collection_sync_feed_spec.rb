require File.join(File.dirname(__FILE__), '..', 'spec_helper')

include SData::Sync

describe SData::ControllerMixin, "#sdata_collection_sync_feed" do

    class BaseClass
      attr_accessor :status
      def id
        1
      end
      
      def self.find(*params)
        self.new
      end
      
      def update_attributes(*params)
        self.status = :updated
        self
      end
    end

    class VirtualModel < SData::Resource
      attr_accessor :baze
    end
    
    before :all do
      VirtualModel.stub :baze_class => BaseClass
      Base = Class.new(ActionController::Base)
      Base.extend SData::ControllerMixin
      Base.acts_as_sdata  :model => VirtualModel
      Base.syncs_sdata
      VirtualModel.acts_as_sdata
    end

    before :each do
      @controller = Base.new
    end  

    describe "given params contain a target digest" do
      before :each do
        pending
        @entry = Atom::Entry.new
        @controller.stub!  :params => { :entry => @entry, :instance_id => 1},
                                        :response => OpenStruct.new,
                                        :request => OpenStruct.new(:fresh? => true),
                           :current_user => OpenStruct.new(:id => 1)
        
        @model = VirtualModel.new(BaseClass.new)
        VirtualModel.should_receive(:new).and_return @model
      end

      describe "when update is successful" do
        before :each do
          @model.baze.stub! :save => true
          @model.stub! :to_atom => stub(:to_xml => '<entry></entry>')
          @model.stub! :owner => OpenStruct.new(:id => 1)
        end

        it "should respond with updated" do
          @controller.should_receive(:render) do |args|
            #TODO: what should I check for?.. Returns 1 right now, is this right?
          end
          @controller.sdata_update_instance
        end
      end
    end
end

