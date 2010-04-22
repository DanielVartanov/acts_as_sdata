require File.join(File.dirname(__FILE__), '..', 'spec_helper')

include SData

describe ControllerMixin, "#sdata_create_instance" do
  describe "given a controller which acts as sdata" do
    before :all do
      Base = Class.new(ActionController::Base)
      Base.extend ControllerMixin

      Model = Class.new
      Base.acts_as_sdata  :model => Model
    end

    before :each do
      @controller = Base.new
    end

    describe "given params contain Atom::Entry" do
      before :each do
        @entry = Atom::Entry.new
        @controller.stub! :params => { :entry => @entry }

        @model = Model.new
        Model.should_receive(:new).and_return @model
      end

      describe "when save is successful" do
        before :each do
          @model.stub! :save => true
          @model.stub! :to_atom => stub(:to_xml => '<entry></entry>')
        end

        it "should respond with 201 (created)" do
          @controller.should_receive(:render) do |args|
            args[:status].should == :created
          end

          @controller.sdata_create_instance
        end

        it "should return updated model as a body" do
          @controller.should_receive(:render) do |args|
            args[:content_type].should == "application/atom+xml; type=entry"
            args[:xml].should == @model.to_atom.to_xml
          end

          @controller.sdata_create_instance
        end
      end

      describe "when save fails" do
        before :each do
          @model.stub! :save => false
          @model.stub! :errors => stub(:to_xml => '<errors></errors>')
        end

        it "should respond with 400 (Bad Request)" do
          @controller.should_receive(:render) do |args|
            args[:status].should == :bad_request
          end

          @controller.sdata_create_instance
        end

        it "should return validation errors as a body" do
          @controller.should_receive(:render) do |args|
            args[:xml].should == @model.errors.to_xml
          end

          @controller.sdata_create_instance
        end
      end
    end
  end
end