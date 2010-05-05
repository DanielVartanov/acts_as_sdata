require File.join(File.dirname(__FILE__), '..', 'spec_helper')

require 'rubygems'
require "usher"
require "usher/interface/rails23"

#Usher::Interface::Rails23.stub!(:install_helpers) # we want no ActionView helpers
Usher::Interface::Rails23.class_eval { def install_helpers; end }

def mock_request(path, method, params)
  request = mock "Request"
  request.should_receive(:path).any_number_of_times.and_return(path)
  request.should_receive(:method).any_number_of_times.and_return(method)
  params = params.with_indifferent_access
  request.should_receive(:path_parameters=).any_number_of_times.with(hash_including(params))
  request.should_receive(:path_parameters).any_number_of_times.and_return(params)
  request
end

ItemsController = Class.new

include SData

describe ControllerMixin, "#sdata_collection" do
  describe "given sdata routes" do
    before :all do
      TestController = Class.new
      @router = Usher::Interface.for(:rails23)
      @router.draw(:delimiters => ['/', '.', '!', '\(', '\)' ]) do |map|
        map.test '/test', :controller => 'test', :action => 'test_action'
        
        map.sdata_resource :items
        map.sdata_resource :items, :prefix => '/sdata/example/crmErp/-/'
      end
    end

    it "recognizes dummy route" do        
      request = mock_request('/test', :get,{})
      @router.recognize(request).should == TestController
    end

    it "recognizes basic route" do        
      request = mock_request('/items', :get,{})
      @router.recognize(request).should == ItemsController
      request.path_parameters.should == {"controller"=>"items", "action"=>"sdata_collection"}
    end

    it "recognizes route with prefix" do        
      request = mock_request('/sdata/example/crmErp/-/items', :get,{})
      @router.recognize(request)
      request.path_parameters.should == {"controller"=>"items", "action"=>"sdata_collection"}
    end

  end
end
