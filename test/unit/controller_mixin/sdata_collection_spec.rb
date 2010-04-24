require File.join(File.dirname(__FILE__), '..', 'spec_helper')

include SData

describe ControllerMixin, "#sdata_collection" do
  describe "given a model which acts as sdata" do
    before :all do
      @time = Time.now - 1.day
      
      class Model
        extend ActiveRecordMixin
        acts_as_sdata
        def id
          1
        end
        def attributes; {} end
        def updated_at
          @time
        end
        def created_by
          OpenStruct.new(:id => 1, :sage_username => 'sage_user')
        end
        def name
          "John Smith"
        end
        def sdata_content
          "Model ##{self.id}: #{self.name}"
        end
      end
    end

    describe "given a controller which acts as sdata" do
      before :all do
        Base = Class.new(ActionController::Base)
        Base.extend ControllerMixin


        Base.acts_as_sdata  :model => Model,
                            :feed => { :id => 'some-unique-id',
                                       :author => 'Test Author',
                                       :path => '/test_resource',
                                       :title => 'List of Test Items',
                                       :default_items_per_page => 10,
                                       :maximum_items_per_page => 100}
                                       
      end

      before :each do
        @controller = Base.new
        @controller.stub! :request => OpenStruct.new(
                            :protocol => 'http', 
                            :host_with_port => 'http://example.com', 
                            :request_uri => Base.sdata_options[:feed][:path],
                            :path => $SDATA_STORE_PATH + '/testResource',
                            :query_parameters => {}),
                          :params => {}
      end

      it "should render Atom feed" do        
        @controller.sdata_options[:model].stub! :all => [Model.new, Model.new]
        @controller.should_receive(:render) do |hash|
          hash[:content_type].should == "application/atom+xml; type=feed"
          hash[:xml].should be_kind_of(Atom::Feed)
          hash[:xml].entries.should == Model.all.map{|entry| entry.to_atom({})}
        end
        @controller.sdata_collection
      end
    end
  end
end