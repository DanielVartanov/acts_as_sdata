require File.join(File.dirname(__FILE__), '..', 'spec_helper')

include SData

describe ControllerMixin, "#build_sdata_feed" do
  describe "given a controller which acts as sdata" do
    before :all do
      Base = Class.new(ActionController::Base)
      Base.extend ControllerMixin
      Base.__send__ :define_method, :build_sdata_feed, lambda { super }

      Base.acts_as_sdata  :feed => { :id => 'some-unique-id',
                                     :author => 'Test Author',
                                     :path => '/test_resource',
                                     :title => 'List of Test Items' }
    end

    before :each do
      @controller = Base.new
      @controller.stub! :request => OpenStruct.new(
                                    :protocol => 'http', 
                                    :host_with_port => 'http://example.com', 
                                    :request_uri => Base.sdata_options[:feed][:path],
                                    :path => SData.store_path + '/-/testResource'),
                        :params => {:dataset => '-'},
                        :sdata_options => {:feed => {}, :model => OpenStruct.new(:name => 'base', :sdata_resource_kind_url => '')}

                                    
    end
    
    it "should return Atom::Feed instance" do
      @controller.build_sdata_feed.should be_kind_of(Atom::Feed)
    end

    it "should not contain any entries" do
      @controller.build_sdata_feed.entries.should be_empty
    end

    it "should adopt passed sdata_options" do
      @controller.build_sdata_feed.id = Base.sdata_options[:feed][:id]
    end
    
    it "should assign categories" do
      @controller.build_sdata_feed.categories.size.should == 1
      @controller.build_sdata_feed.categories[0].term.should == 'bases'
      @controller.build_sdata_feed.categories[0].label.should == 'Bases'
      @controller.build_sdata_feed.categories[0].scheme.should == "http://schemas.sage.com/sdata/categories"
    end
  end
end