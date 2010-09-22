require File.join(File.dirname(__FILE__), '..', 'spec_helper')

include SData

describe ControllerMixin, "#sdata_update_instance" do
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
      Base.extend ControllerMixin
      Base.acts_as_sdata  :model => VirtualModel
      VirtualModel.acts_as_sdata
    end

    before :each do
      pending # not currently supported
      @controller = Base.new
    end  

    describe "given params contain Atom::Entry" do
      before :each do
        @entry = Atom::Entry.new
        @controller.stub!  :params => { :entry => @entry, :instance_id => 1},
                                        :response => OpenStruct.new,
                                        :request => OpenStruct.new(:fresh? => true)
        
        @model = VirtualModel.new(BaseClass.new)
        VirtualModel.should_receive(:new).and_return @model
      end

      describe "when update is successful" do
        before :each do
          @model.baze.stub! :save => true
          @model.stub! :to_atom => stub(:to_xml => '<entry></entry>')
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

