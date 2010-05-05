require File.join(File.dirname(__FILE__), '..', 'spec_helper')

require 'rubygems'
require "usher"
require "usher/interface/rails23"

require 'ruby-debug'

# we want no ActionView helpers
class Usher
  module Interface
    class Rails23
	def install_helpers
	end
    end
  end
end

def mock_request(path, method, params)
  request = mock "Request"
  request.should_receive(:path).any_number_of_times.and_return(path)
  request.should_receive(:method).any_number_of_times.and_return(method)
  params = params.with_indifferent_access
  request.should_receive(:path_parameters=).any_number_of_times.with(hash_including(params))
  request.should_receive(:path_parameters).any_number_of_times.and_return(params)
  request
end


TestController = Class.new
ItemsController = Class.new

include SData

describe ControllerMixin, "#sdata_collection" do
  describe "given an usher router" do
    before :all do
	    
	#ActionController::Routing.module_eval "remove_const(:Routes); Routes = Usher::Interface.for(:rails23)"
	@router = Usher::Interface.for(:rails23)
	#@router = ActionController::Routing::Routes

	#require "usher"
	#@router = Usher.new :delimiters => ['/', '.', '!', '\(', '\)' ]
    end


     it "should something" do        

      	#target_route = @route_set.add_route('/sample', :controller => 'sample', :action => 'action', :conditions => {:protocol => 'http'}).unrecognizable!
      	#@route_set.recognize(build_request({:method => 'get', :path => '/sample', :protocol => 'http'})).should be_nil

	@router.draw(:delimiters => ['/', '.', '!', '\(', '\)' ]) do |map|
	  map.test '/test', :controller => 'test', :action => 'test_action'
	  #map.test '/items', :controller => 'items', :action => 'test_action'

	  map.sdata_resource :items
	  #map.sdata_resource :items, :prefix => '/sdata/example/crmErp/-/'
	end
	
	request = mock_request('/test', :get,{})
	@router.recognize(request).should == TestController

	request = mock_request('/items', :get,{})
	@router.recognize(request).should == ItemsController
	

	#@router.recognize request('/test', 'get', { }#:controller => 'items', :action => 'collection'})
      
        #@controller.should_receive(:render) do |hash|
        #  hash[:content_type].should == "application/atom+xml; type=feed"
        #  hash[:xml].should be_kind_of(Atom::Feed)
        #  hash[:xml].entries.should == Model.all.map{|entry| entry.to_atom({})}
        #end
        #@controller.sdata_collection
      #end

    end
  end
end
