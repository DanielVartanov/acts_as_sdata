require File.join(File.dirname(__FILE__), '..', 'spec_helper')

include SData

describe ControllerMixin, "#sdata_collection" do
  describe "given a model which acts as sdata" do
    before :all do
      @time = Time.now - 1.day
      
      class ModelBob
        extend SData::ActiveRecordExtensions::Mixin
        acts_as_sdata
        def self.name
          "SData::Contracts::CrmErp::ModelBob"
        end
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
          "ModelBob ##{self.id}: #{self.name}"
        end
        def payload_map
          {}
        end
      end
    end

    describe "given a controller which acts as sdata" do
      before :all do
        Base = Class.new(ActionController::Base)
        Base.extend ControllerMixin


        Base.acts_as_sdata  :model => ModelBob,
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
                            :path => SData.store_path + '/-/testResource',
                            :query_parameters => {}),
                          :params => {}
        @controller.sdata_options[:model].stub! :all => [ModelBob.new, ModelBob.new]
      end

      it "should render Atom feed" do        

        @controller.should_receive(:render) do |hash|
          hash[:content_type].should == "application/atom+xml; type=feed"
          hash[:xml].should be_kind_of(Atom::Feed)
          hash[:xml].entries.should == ModelBob.all.map{|entry| entry.to_atom({})}
        end
        @controller.sdata_collection
      end

    end
  end
end