require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')

include SData

describe ControllerMixin do
  describe "given a class which behaves like ActionController::Base" do
    before :all do
      Base = Class.new(ActionController::Base)
    end

    describe "when SData::ControllerMixin is included" do
      before :each do
        Base.__send__ :include, ControllerMixin
      end

      it "class should respond to .acts_as_sdata" do
        Base.should respond_to(:acts_as_sdata)
        Base.new.should_not respond_to(:acts_as_sdata)
      end

      it "instance should respond to methods of ControllerMixin::InstanceMethods" do
        Base.new.should respond_to(:build_sdata_feed)
        Base.should_not respond_to(:build_sdata_feed)
      end

      describe ".acts_as_sdata" do
        before :each do
          Model = Class.new
          Base.acts_as_sdata  :model => Model,
                              :feed => { :id => 'some-unique-id',
                                         :author => 'Test Author',
                                         :path => '/test_resource',
                                         :title => 'List of Test Items' }
          

          @controller = Base.new          
        end

        describe "#build_sdata_feed" do
          it "should return Atom::Feed instance" do
            @controller.send(:build_sdata_feed).should be_kind_of(Atom::Feed)
          end

          it "should not contain any entries" do
            @controller.send(:build_sdata_feed).entries.should be_empty
          end
        end

        describe "#sdata_scope" do
          describe "when params contain :predicate key" do
            before :each do
              @controller.stub! :params => { :predicate => 'born_at gt 1900' }
            end

            it "should return entity apply to SData::Predicate for conditions" do
              Model.should_receive(:all).with :conditions => ['? > ?', 'born_at', '1900']
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
    end
  end
end
