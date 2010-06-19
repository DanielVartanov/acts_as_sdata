require File.join(File.dirname(__FILE__), '..', 'spec_helper')

module Atom
  class Feed
    def opensearch(key)
      simple_extensions["{#{SData.config[:schemas]["opensearch"]},#{key}}"][0]
    end
  end
end

describe SData::ControllerMixin, "#sdata_collection" do
  describe "given a model which acts as sdata" do
    before :all do
      @time = Time.now - 1.day
      
      class Model
        extend SData::ActiveRecordExtensions::Mixin
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
        
        def name=(a_name)
          @name=a_name
        end
        def name
          @name || "John Smith"
        end
        def sdata_content
          "contains #{self.name}"
        end
      end
    end

    def stub_params(params,query=true)
      @controller.request.query_parameters = params if query
      @controller.stub! :params => params.merge({:dataset => '-'})
    end

    describe "given a controller which acts as sdata" do
      before :all do
        Base = Class.new(ActionController::Base)
        Base.extend SData::ControllerMixin


        Base.acts_as_sdata  :model => Model,
                            :feed => { :id => 'some-unique-id',
                                       :author => 'Test Author',
                                       :path => '/test_resource',
                                       :title => 'List of Test Items',
                                       :default_items_per_page => 5,
                                       :maximum_items_per_page => 100}
                                       
      end

      before :each do
        @controller = Base.new
        @controller.stub! :request => OpenStruct.new(
                            :protocol => 'http://', 
                            :host_with_port => 'http://example.com', 
                            :request_uri => Base.sdata_options[:feed][:path],
                            :query_parameters => {}),
                          :params => {}
      end
      
      describe "given an empty record collection" do
        before :each do
          @controller.sdata_options[:model].stub! :all => []
   
        end
        it "should display default opensearch values" do
          stub_params({:dataset => '-'}, false)
          @controller.should_receive(:render) do |hash|
            hash[:xml].opensearch("itemsPerPage").should == Base.sdata_options[:feed][:default_items_per_page]
            hash[:xml].opensearch("totalResults").should == 0
            hash[:xml].opensearch("startIndex").should == 1
            hash[:xml].entries.size.should == 0
            hash[:xml].links.size.should == 1
            hash[:xml].links[0].rel.should == 'self'
            hash[:xml].links[0].href.should == "http://www.example.com/sdata/example/myContract/-/models"
          end
          @controller.sdata_collection
        end

        it "should correctly parse opensearch values to xml" do
          @controller.should_receive(:render) do |hash|
            hash[:xml].to_xml.gsub(/\n\s*/, '').match(/<feed.*<opensearch:itemsPerPage>5<\/opensearch:itemsPerPage>.*<\/feed>$/).should_not == nil
            hash[:xml].to_xml.gsub(/\n\s*/, '').match(/<feed.*<opensearch:totalResults>0<\/opensearch:totalResults>.*<\/feed>$/).should_not == nil
            hash[:xml].to_xml.gsub(/\n\s*/, '').match(/<feed.*<opensearch:startIndex>1<\/opensearch:startIndex>.*<\/feed>$/).should_not == nil
          end
          @controller.sdata_collection
        end

      end

      describe "given a non empty record collection of 15 records" do
        
        def models_with_serial_names
          models = []
          for i in 1..15 do
            model = Model.new
            model.name = i.to_s
            models << model
          end
          models
        end
        
        def verify_content_for(entries, range)
          counter = 0
          range.entries.size.should == entries.size
          range.each do |num|
            entries[counter].content.should == "contains #{num}"
            counter+=1
          end
        end
        
        def verify_links_for(links, conditions)
          present_types = links.collect{|l|l.rel}
          %w{self first last previous next}.each do |type|
            if conditions[type.to_sym].nil?
              present_types.include?(type).should == false
            else
              link = links.detect{|l|(l.rel==type)}
              link.should_not == nil
              link.href.split('?')[0].should == conditions[:path] if conditions[:path]
              query = link.href.split('?')[1]

              if conditions[:count]
                value = query.match(/count=\-?(\w|\d)*/).to_s.split('=')[1].to_s
                value.should == conditions[:count]
              elsif conditions[:count] == false #not nil
                (query.nil? || !query.include?('count')).should == true
              end

              if conditions[type.to_sym] == false
                (query.nil? || !query.include?('startIndex')).should == true
              else
                page = query.match(/startIndex=\-?\d*/).to_s.split('=')[1].to_s
                page.should == conditions[type.to_sym]
              end
            end
          end
        end  
        before :each do
          @controller.sdata_options[:model].stub! :all => models_with_serial_names

        end
        
        it "should display default opensearch and link values" do
          stub_params({})
          @controller.should_receive(:render) do |hash|
            hash[:xml].opensearch("itemsPerPage").should == Base.sdata_options[:feed][:default_items_per_page]
            hash[:xml].opensearch("totalResults").should == 15
            hash[:xml].opensearch("startIndex").should == 1
            hash[:xml].entries.size.should == 5
            verify_content_for(hash[:xml].entries, 1..5)
            verify_links_for(hash[:xml].links, :path => "http://www.example.com/sdata/example/myContract/-/models", 
              :count => false, :self => false, :first => '1', :last => '11', :next => '6')
          end
          @controller.sdata_collection
        end

        it "properly calculate last page when itemsPerPage is not exact multiple of totalResults" do
          stub_params({:count => '4'})
          @controller.should_receive(:render) do |hash|
            hash[:xml].opensearch("itemsPerPage").should == 4
            hash[:xml].opensearch("totalResults").should == 15
            hash[:xml].opensearch("startIndex").should == 1
            hash[:xml].entries.size.should == 4
            verify_content_for(hash[:xml].entries, 1..4)
            verify_links_for(hash[:xml].links, 
              :count => '4', :self => false, :first => '1', :last => '13', :next => '5')
          end
          @controller.sdata_collection
        end
        
        it "should reject zero start index" do
          stub_params({:startIndex => '0'})
          @controller.should_receive(:render) do |hash|
            hash[:xml].opensearch("itemsPerPage").should == Base.sdata_options[:feed][:default_items_per_page]
            hash[:xml].opensearch("totalResults").should == 15
            hash[:xml].opensearch("startIndex").should == 1
            hash[:xml].entries.size.should == 5
            verify_content_for(hash[:xml].entries, 1..5)
            verify_links_for(hash[:xml].links, :self => '0', :first => '1', :last => '11', :next => '6')
          end
          @controller.sdata_collection
        end        

        it "should reject negative start index" do
         stub_params({:startIndex => '-5'})
          @controller.should_receive(:render) do |hash|
            hash[:xml].opensearch("itemsPerPage").should == Base.sdata_options[:feed][:default_items_per_page]
            hash[:xml].opensearch("totalResults").should == 15
            hash[:xml].opensearch("startIndex").should == 1
            hash[:xml].entries.size.should == 5
            verify_content_for(hash[:xml].entries, 1..5)
            verify_links_for(hash[:xml].links, :self => '-5', :first => '1', :last => '11', :next => '6')
          end
          @controller.sdata_collection
        end  

        it "should accept positive start index which is not greater than totalResults-itemsPerPage+1 and return itemsPerPage records" do
          stub_params({:startIndex => '11'})
          @controller.should_receive(:render) do |hash|
            hash[:xml].opensearch("itemsPerPage").should == Base.sdata_options[:feed][:default_items_per_page]
            hash[:xml].opensearch("totalResults").should == 15
            hash[:xml].opensearch("startIndex").should == 11
            hash[:xml].entries.size.should == 5
            verify_content_for(hash[:xml].entries, 11..15)
            verify_links_for(hash[:xml].links, :self => '11', :first => '1', :last => '11', :previous => '6')
          end
          @controller.sdata_collection
        end  

        it "should accept positive start index which is greater than totalResults-itemsPerPage+1 but not greater than totalResults, and return fitting itemsPerPage" do
          stub_params({:startIndex => '12'})
          @controller.should_receive(:render) do |hash|
            hash[:xml].opensearch("itemsPerPage").should == Base.sdata_options[:feed][:default_items_per_page]
            hash[:xml].opensearch("totalResults").should == 15
            hash[:xml].opensearch("startIndex").should == 12
            hash[:xml].entries.size.should == 4
            verify_content_for(hash[:xml].entries, 12..15)
            verify_links_for(hash[:xml].links, :self => '12', :first => '1', :last => '12', :previous => '7')
          end
          @controller.sdata_collection

          stub_params({:startIndex => '15'})
          @controller.should_receive(:render) do |hash|
            hash[:xml].opensearch("itemsPerPage").should == Base.sdata_options[:feed][:default_items_per_page]
            hash[:xml].opensearch("totalResults").should == 15
            hash[:xml].opensearch("startIndex").should == 15
            hash[:xml].entries.size.should == 1
            verify_content_for(hash[:xml].entries, 15..15)
            verify_links_for(hash[:xml].links, :self => '15', :first => '1', :last => '15', :previous => '10')
          end
          @controller.sdata_collection

        end  
        
        #RADAR: if this should generate error (e.g. OutOfBounds exception), this spec needs to change
        it "should accept positive start index which is greater than totalResults-itemsPerPage+1 but return nothing" do
          stub_params({:startIndex => '16'})
          @controller.should_receive(:render) do |hash|
            hash[:xml].opensearch("itemsPerPage").should == Base.sdata_options[:feed][:default_items_per_page]
            hash[:xml].opensearch("totalResults").should == 15
            hash[:xml].opensearch("startIndex").should == 16
            hash[:xml].entries.size.should == 0
            verify_links_for(hash[:xml].links, :self => '16', :first => '1', :last => '11', :previous => '11')
          end
          @controller.sdata_collection
        end  

        it "should combine start index with count" do
          stub_params({:startIndex => '9', :count => '10'})
          @controller.should_receive(:render) do |hash|
            hash[:xml].opensearch("itemsPerPage").should == 10
            hash[:xml].opensearch("totalResults").should == 15
            hash[:xml].opensearch("startIndex").should == 9
            hash[:xml].entries.size.should == 7
            verify_content_for(hash[:xml].entries, 9..15)
            verify_links_for(hash[:xml].links, :count => '10', :self => '9', :first => '1', :last => '9', :previous => '1')
          end
          @controller.sdata_collection
        end 

        it "should accept query to return no records" do
          stub_params({:count => '0'})
          @controller.should_receive(:render) do |hash|
            hash[:xml].opensearch("itemsPerPage").should == 0
            hash[:xml].opensearch("totalResults").should == 15
            hash[:xml].opensearch("startIndex").should == 1
            hash[:xml].entries.size.should == 0
            verify_links_for(hash[:xml].links, :count => '0', :self => false)
          end
          @controller.sdata_collection
        end

        it "should accept query to return more records than default value but less than maximum value" do
          stub_params({:count => '50'})
          @controller.should_receive(:render) do |hash|
            hash[:xml].opensearch("itemsPerPage").should == 50
            hash[:xml].opensearch("totalResults").should == 15
            hash[:xml].opensearch("startIndex").should == 1
            hash[:xml].entries.size.should == 15
            verify_content_for(hash[:xml].entries, 1..15)
            verify_links_for(hash[:xml].links, 
              :count => '50', :self => false)
          end
          @controller.sdata_collection
        end

        it "should reject query to return more records than maximum value, and use maximum instead" do
          stub_params({:count => '300'})
          @controller.should_receive(:render) do |hash|
            hash[:xml].opensearch("itemsPerPage").should == 100
            hash[:xml].opensearch("totalResults").should == 15
            hash[:xml].opensearch("startIndex").should == 1
            hash[:xml].entries.size.should == 15
            verify_content_for(hash[:xml].entries, 1..15)
            verify_links_for(hash[:xml].links, 
              :count => '300', :self => false)
          end
          @controller.sdata_collection
        end

        #FIXME: breaks right now. would be nice to fix without breaking any other tests
        #find out what's a method to determine whether a string is numerical ('asdf'.to_i returns 0 which is bad)
        it "should reject invalid value and return default instead" do
          stub_params({:count => 'asdf'})
          @controller.should_receive(:render) do |hash|
            hash[:xml].opensearch("itemsPerPage").should == 5
            hash[:xml].opensearch("totalResults").should == 15
            hash[:xml].opensearch("startIndex").should == 1
            hash[:xml].entries.size.should == 5
            verify_content_for(hash[:xml].entries, 1..5)
            verify_links_for(hash[:xml].links, :path => "http://www.example.com/sdata/example/myContract/-/models", 
              :count => 'asdf', :self => false, :first => '1', :last => '11', :next => '6')
          end
          @controller.sdata_collection
        end
        
        it "should reject negative value and return default instead" do
          stub_params({:count => '-3'})
          @controller.should_receive(:render) do |hash|
            hash[:xml].opensearch("itemsPerPage").should == 5
            hash[:xml].opensearch("totalResults").should == 15
            hash[:xml].opensearch("startIndex").should == 1
            hash[:xml].entries.size.should == 5
            verify_content_for(hash[:xml].entries, 1..5)
            verify_links_for(hash[:xml].links, :path => "http://www.example.com/sdata/example/myContract/-/models", 
              :count => '-3', :self => false, :first => '1', :last => '11', :next => '6')
          end
          @controller.sdata_collection
        end
        
        #RADAR: in this case, going from initial page to previous page will show 'next' page as not equal
        #to initial page, since startIndex is currently not supported to be negative (and show X records on
        #first page where X = itemsPerPage+startIndex, and startIndex is negative and thus substracted) 
        #if this is needed, spec will change (but in theory this would conflict with SData spec which
        #specifies that ALL pages must have exactly the same items as itemsPerPage with possible exception 
        #of ONLY the last page, and not the first one.
        it "should combine start index with count not exceeding totals" do
          stub_params({:startIndex => '3', :count => '5'})
          @controller.should_receive(:render) do |hash|
            hash[:xml].opensearch("itemsPerPage").should == 5
            hash[:xml].opensearch("totalResults").should == 15
            hash[:xml].opensearch("startIndex").should == 3
            hash[:xml].entries.size.should == 5
            verify_content_for(hash[:xml].entries, 3..7)
            verify_links_for(hash[:xml].links, :path => "http://www.example.com/sdata/example/myContract/-/models", 
              :count => '5', :self => '3', :first => '1', :last => '13', :previous => '1', :next => '8')
          end
          @controller.sdata_collection
        end  
 
        it "should combine start index with count exceeding totals" do
          stub_params({:startIndex => '9', :count => '10'})
          @controller.should_receive(:render) do |hash|
            hash[:xml].opensearch("itemsPerPage").should == 10
            hash[:xml].opensearch("totalResults").should == 15
            hash[:xml].opensearch("startIndex").should == 9
            hash[:xml].entries.size.should == 7
            verify_content_for(hash[:xml].entries, 9..15)
            verify_links_for(hash[:xml].links, :path => "http://www.example.com/sdata/example/myContract/-/models", 
              :count => '10', :self => '9', :first => '1', :last => '9', :previous => '1')
          end
          @controller.sdata_collection
        end  
  
      end
    
    end
  end
end