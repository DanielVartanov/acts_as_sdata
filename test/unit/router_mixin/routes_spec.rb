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
        map.sdata_resource :items, :prefix => '/sdata/example/crmErp'
      end
    end

    it "recognizes dummy route" do        
      request = mock_request('/test', :get,{})
      @router.recognize(request).should == TestController
    end

    it "recognizes collection route" do        
      request = mock_request('/items', :get,{})
      @router.recognize(request).should == ItemsController
      request.path_parameters.should == {"controller"=>"items", "action"=>"sdata_collection"}
    end

    it "recognizes collection route with default prefix" do        
      request = mock_request('/sdata/example/crmErp/-/items', :get,{})
      @router.recognize(request)
      request.path_parameters.should == {"controller"=>"items", "action"=>"sdata_collection", "dataset" => "-"}
    end

    it "recognizes collection route with custom prefix" do        
      request = mock_request('/sdata/example/crmErp/asdf/items', :get,{})
      @router.recognize(request)
      request.path_parameters.should == {"controller"=>"items", "action"=>"sdata_collection", "dataset" => "asdf"}
    end

    describe "search with parenthesis" do
      it "recognizes simple instance query in parenthesis" do
        request = mock_request("/items(id gt 1)", :get, {})
        @router.recognize(request)
        request.path_parameters.should == {"controller"=>"items", "action"=>"sdata_show_instance", "predicate"=>"id gt 1"}
      end

      it "recognizes instance query in parenthesis within linked items" do
        request = mock_request("/items/$linked(id gt 1)", :get, {})
        @router.recognize(request)
        request.path_parameters.should == {"controller"=>"items", "action"=>"sdata_show_instance", "condition"=>"$linked", "predicate"=>"id gt 1"}
      end
    end

    describe "scoping with where-clauses" do
      it "recognizes scoping query within non-linked items" do
        request = mock_request("/items", :get, {'where name eq asdf' => nil})
        @router.recognize(request)
        request.path_parameters.should == {"controller"=>"items", "action"=>"sdata_collection", "where name eq asdf" => nil}
      end
      
      it "recognizes scoping query within linked items" do
        request = mock_request("/items/$linked", :get,  {'where name eq asdf' => nil})
        @router.recognize(request)
        request.path_parameters.should == {"controller"=>"items", "action"=>"sdata_collection", "condition"=>"$linked", "where name eq asdf" => nil}
      end
    end

    it "recognizes collection route with linked collection" do        
      request = mock_request("/items/$linked", :get, {})
      @router.recognize(request)
      request.path_parameters.should == {"controller"=>"items", "action"=>"sdata_collection", "condition"=>"$linked" }
    end

    it "recognizes syncSource route for collection" do        
      request = mock_request("/items/$syncSource", :post, {})
      @router.recognize(request)
      request.path_parameters.should == {"controller"=>"items", "action"=>"sdata_collection_sync_feed" }
    end

    it "recognizes syncSource status route" do        
      request = mock_request("/items/$syncSource('DD052E5C-BFAD-4ffa-8D54-D696E4959497')", :get, {})
      @router.recognize(request)
      request.path_parameters.should == {"controller"=>"items", "action"=>"sdata_collection_sync_feed_status", "trackingID" => "'DD052E5C-BFAD-4ffa-8D54-D696E4959497'" }
    end

    it "recognizes syncSource delete route" do        
      request = mock_request("/items/$syncSource('bobob')", :delete, {})
      @router.recognize(request)
      request.path_parameters.should == {"controller"=>"items", "action"=>"sdata_collection_sync_feed_delete", "trackingID" => "'bobob'"}
    end

    it "recognizes syncResults route for collection" do        
      request = mock_request("/items/$syncResults('bobob')", :post, {})
      @router.recognize(request)
      request.path_parameters.should == {"controller"=>"items", "action"=>"sdata_collection_sync_results", "trackingID" => "'bobob'" }
    end

    it "recognizes create link route" do        
      request = mock_request("/items/$linked", :post, {})
      @router.recognize(request)
      request.path_parameters.should == {"controller"=>"items", "action"=>"sdata_create_link", "condition"=>"$linked" }
    end

    it "recognizes instance route with id" do        
      request = mock_request("/items('123')", :get, {})
      @router.recognize(request)
      request.path_parameters.should == {"controller"=>"items", "action"=>"sdata_show_instance", "instance_id" => "'123'"}
    end

    it "recognizes instance route with linked uuid" do        
      request = mock_request("/items/$linked('uuid')", :get, {})
      @router.recognize(request)
      request.path_parameters.should == {"controller"=>"items", "action"=>"sdata_show_instance", "condition" => "$linked", "instance_id" => "'uuid'"}
    end

    
  end
end
