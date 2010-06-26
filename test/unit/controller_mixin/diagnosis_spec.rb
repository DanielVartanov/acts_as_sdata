require File.join(File.dirname(__FILE__), '..', 'spec_helper')

include SData

describe ControllerMixin, "#sdata_collection" do
  describe "given a model which acts as sdata" do
    before :all do
      Customer.extend SData::ActiveRecordExtensions::Mixin
      Customer.class_eval { acts_as_sdata }
      class EntryDiagnosisCustomer < Customer
        def resource_header_attributes(*params)
          raise 'Exception while trying to construct payload map'
        end
      end
      class FeedDiagnosisCustomer < Customer
        def id
          raise 'Exception while trying to get customer id'
        end
      end
    end

    describe "given a controller which acts as sdata" do
      before :all do
        class Base < ActionController::Base
          extend ControllerMixin
   
          Base.acts_as_sdata  :model => Customer,
                              :feed => { :id => 'some-unique-id',
                                         :author => 'Test Author',
                                         :path => '/test_resource',
                                         :title => 'List of Test Items',
                                         :default_items_per_page => 10,
                                         :maximum_items_per_page => 100}
        end
      end
  
      before :each do
        @controller = Base.new
        @controller.stub! :request => OpenStruct.new(
                            :protocol => 'http://', 
                            :host_with_port => 'example.com', 
                            :request_uri => Base.sdata_options[:feed][:path],
                            :path => SData.store_path + '/-/testResource',
                            :query_parameters => {}),
                         :params => {}
      end

      #TODO: spec trying to populate xpaths for errored entries

      context "when one of entries is erroneous" do
        before :each do
          @controller.sdata_options[:model].stub! :all => [EntryDiagnosisCustomer.new, Customer.new]
        end

        it "should respond with both entries" do
          @controller.should_receive(:render) do |hash|
            hash[:xml].entries.size.should == 2

            failed_entries = hash[:xml].entries.reject{ |e| e.diagnosis.nil? }
            successful_entries = hash[:xml].entries.select { |e| e.diagnosis.nil? }

            failed_entries.size.should == 1
            successful_entries.size.should == 1
          end

          @controller.sdata_collection
        end

        it "should compose diagnosis entry correctly" do
          @controller.should_receive(:render) do |hash|
            failed_entry = hash[:xml].entries.reject{ |e| e.diagnosis.nil? }.first

            failed_entry.id.should_not be_nil
            failed_entry.content.should_not be_nil
            failed_entry.sdata_payload.should be_nil
          end
          @controller.sdata_collection
        end

        it "should compose sdata:diagnosis properties correctly" do
          @controller.should_receive(:render) do |hash|
            failed_entry = hash[:xml].entries.reject{ |e| e.diagnosis.nil? }.first
            entry = Nokogiri::XML(failed_entry.to_xml, nil, nil, Nokogiri::XML::ParseOptions::DEFAULT_XML | Nokogiri::XML::ParseOptions::NOBLANKS)

            diagnosis = entry.xpath('/xmlns:entry/sdata:diagnosis').first
            diagnosis.children.size.should == 4
            
            diagnosis.xpath('sdata:severity/text()').to_s.should == 'error'
            diagnosis.xpath('sdata:sdataCode/text()').to_s.should == 'ApplicationDiagnosis'
            diagnosis.xpath('sdata:message/text()').to_s.should == "Exception while trying to construct payload map"
            diagnosis.xpath('sdata:stackTrace/text()').to_s.include?('/diagnosis_spec.rb').should be_true
          end
          @controller.sdata_collection
        end

        it "should correctly compose regular entry as well" do
          @controller.should_receive(:render) do |hash|
            successful_entry = hash[:xml].entries.select{ |e| e.diagnosis.nil? }.first
            successful_entry.id.should_not be_nil
            successful_entry.content.should_not be_nil
            successful_entry.sdata_payload.should_not be_nil
            successful_entry.content.should_not be_nil
          end
          @controller.sdata_collection
        end
      end

      it "should construct multiple diagnosis elements within the same entry to describe multiple caught exceptions" do
        pending #not implemented, difficulties with rAtom
      end
  
      it "should construct diagnosis for caught Feed intercepting uncaught Entry exception" do      
        #TODO: spec trying to populate xpaths for errored entries
        @controller.sdata_options[:model].stub! :all => [FeedDiagnosisCustomer.new, Customer.new]
        @controller.should_receive(:render) do |hash|
          hash[:xml].entries.size.should == 1
          hash[:xml].entries.each do |entry|
            entry.id.should_not be_nil
            entry.sdata_payload.should_not be_nil
            entry.content.should_not be_nil
            entry.diagnosis.should be_nil
          end
          hash[:xml].simple_extensions['{http://schemas.sage.com/sdata/2008/1,diagnosis}'].size.should == 1
          feed_diagnosis = hash[:xml].simple_extensions['{http://schemas.sage.com/sdata/2008/1,diagnosis}'][0]
          feed_diagnosis.children.detect{|x|x.name=='sdata:severity'}.children[0].to_s.should == 'error'
          feed_diagnosis.children.detect{|x|x.name=='sdata:sdataCode'}.children[0].to_s.should == 'ApplicationDiagnosis'
          feed_diagnosis.children.detect{|x|x.name=='sdata:message'}.children[0].to_s.should == "Exception while trying to get customer id"           
          feed_diagnosis.children.detect{|x|x.name=='sdata:stackTrace'}.children[0].to_s.include?('/diagnosis_spec.rb').should == true
        end
        @controller.sdata_collection
      end
      
      it "should be able to combine feed and entry exceptions" do
        @controller.sdata_options[:model].stub! :all => [FeedDiagnosisCustomer.new, FeedDiagnosisCustomer.new, EntryDiagnosisCustomer.new, Customer.new, Customer.new]
        @controller.should_receive(:render) do |hash|
          hash[:xml].entries.size.should == 3
          hash[:xml].entries.collect{|e|e if e.diagnosis.nil?}.compact.size.should == 2
          hash[:xml].entries.collect{|e|e if !e.diagnosis.nil?}.compact.size.should == 1
          hash[:xml].entries.each do |entry|
            entry.id.should_not be_nil
            entry.content.should_not be_nil
            if entry.diagnosis.nil?
              entry.sdata_payload.should_not be_nil
            else
              entry.sdata_payload.should be_nil
              entry.diagnosis[0].children.detect{|x|x.name=='sdata:severity'}.children[0].to_s.should == 'error'
              entry.diagnosis[0].children.detect{|x|x.name=='sdata:sdataCode'}.children[0].to_s.should == 'ApplicationDiagnosis'
              entry.diagnosis[0].children.detect{|x|x.name=='sdata:message'}.children[0].to_s.should == "Exception while trying to construct payload map"
            end
          end
          hash[:xml].simple_extensions['{http://schemas.sage.com/sdata/2008/1,diagnosis}'].size.should == 2
          feed_diagnoses = hash[:xml].simple_extensions['{http://schemas.sage.com/sdata/2008/1,diagnosis}']
          feed_diagnoses.each do |failed_entry|
            failed_entry.children.detect{|x|x.name=='sdata:severity'}.children[0].to_s.should == 'error'
            failed_entry.children.detect{|x|x.name=='sdata:sdataCode'}.children[0].to_s.should == 'ApplicationDiagnosis'
            failed_entry.children.detect{|x|x.name=='sdata:message'}.children[0].to_s.should == "Exception while trying to get customer id"
          end
        end
        @controller.sdata_collection
      end
      
      it "should construct standalone exception with full xml header" do
        @controller.stub!(:sdata_scope).and_raise(Exception.new('exception rendering collection'))
        @controller.should_receive(:render) do |hash|
          hash[:xml].class.should == LibXML::XML::Document
          hash[:xml].root.name.should == "sdata:diagnoses"
          hash[:xml].root.children.size.should == 1
          hash[:xml].root.children[0].name.should == "sdata:diagnosis"
          hash[:xml].root.children[0].children.size.should == 4
          attributes = hash[:xml].root.children[0].children.collect{|c|c.name}.sort
          attributes.should == ["sdata:message", "sdata:sdataCode", "sdata:severity", "sdata:stackTrace"]
          hash[:xml].root.children[0].children.each do |child|
            child.children.size.should == 1
            case child.name
            when "sdata:message"
              child.children[0].to_s.should == "exception rendering collection"
            when "sdata:sdataCode"
              child.children[0].to_s.should == "ApplicationDiagnosis"
            when "sdata:severity"
              child.children[0].to_s.should == "error"
            end
          end
        end
        @controller.sdata_collection
      end
      

    end

    describe "given a controller which acts as sdata" do
      before :all do
        
        class NewBase < ActionController::Base
           sdata_rescue_support
           rescue_from Exception, :with => :global_rescue
           def global_rescue
             if request.env['REQUEST_URI'].match(/^\/sdata/)
               #this case must happen in ALL rails environments (dev, test, prod, etc.)
               sdata_global_rescue(exception, request.env['REQUEST_URI'])
             end
           end
        end
        NewBase.extend ControllerMixin
        NewBase.extend SData::ApplicationControllerMixin
        NewBase.acts_as_sdata  :model => Customer,
                            :feed => { :id => 'some-unique-id',
                                       :author => 'Test Author',
                                       :path => '/test_resource',
                                       :title => 'List of Test Items',
                                       :default_items_per_page => 10,
                                       :maximum_items_per_page => 100}
                                         
      end
  
      before :each do
        @controller = NewBase.new
        @controller.stub! :request => OpenStruct.new(
                            :protocol => 'http://', 
                            :host_with_port => 'example.com', 
                            :request_uri => NewBase.sdata_options[:feed][:path],
                            :path => SData.store_path + '/-/testResource',
                            :query_parameters => {}),
                         :params => {}
      end  
      
      it "should catch unhandled feed exception in a handled method exception" do
        pending #can't figure out how to do it here, perhaps only easily possible in cucumber
      end
    end
    
  end
end