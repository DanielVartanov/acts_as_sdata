require File.join(File.dirname(__FILE__), '..', '..', '..', 'spec_helper')

include SData

describe ControllerMixin, "#sdata_collection" do
  describe "given a model which acts as sdata" do
    before :all do
      Model = Class.new      
      Model.extend ActiveRecordExtentions
      Model.acts_as_sdata
      Model.stub! :all => [Model.new, Model.new]
    end

    describe "given a controller which acts as sdata" do
      before :all do
        Base = Class.new(ActionController::Base)
        Base.__send__ :include, ControllerMixin


        Base.acts_as_sdata  :model => Model,
                            :feed => { :id => 'some-unique-id',
                                       :author => 'Test Author',
                                       :path => '/test_resource',
                                       :title => 'List of Test Items' }
      end

      before :each do
        @controller = Base.new
        @controller.stub! :sdata_scope => Model.all
      end

      # TODO: doesn't seem as a useful test

      it "should render Atom feed" do        
        @controller.should_receive(:render) do |hash|
          hash[:content_type].should == "application/atom+xml; type=feed"
          hash[:xml].should be_kind_of(Atom::Feed)
          hash[:xml].entries.should == Model.all.map(&:to_atom)
        end
        @controller.sdata_collection
      end
    end
  end
end