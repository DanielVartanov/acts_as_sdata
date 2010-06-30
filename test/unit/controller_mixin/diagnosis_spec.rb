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

      context "when one entry is erroneous" do
        before :each do
          @controller.sdata_options[:model].stub! :all => [EntryDiagnosisCustomer.new, Customer.new]
          @controller.should_receive(:render) do |hash|
            @feed = hash[:xml]
          end
          @controller.sdata_collection
        end

        it "should respond with both entries" do
          @feed.entries.size.should == 2

          failed_entries = @feed.entries.reject{ |e| e.diagnosis.nil? }
          successful_entries = @feed.entries.select { |e| e.diagnosis.nil? }

          failed_entries.size.should == 1
          successful_entries.size.should == 1
        end

        it "should compose diagnosis entry correctly" do
          failed_entry = @feed.entries.reject{ |e| e.diagnosis.nil? }.first

          failed_entry.id.should_not be_nil
          failed_entry.content.should_not be_nil
          failed_entry.sdata_payload.should be_nil
        end

        it "should compose sdata:diagnosis properties correctly" do
          failed_entry = @feed.entries.reject{ |e| e.diagnosis.nil? }.first
          failed_entry = parse_xml(failed_entry.to_xml)

          diagnosis = failed_entry.xpath('/xmlns:entry/sdata:diagnosis').first
          diagnosis.children.size.should == 4

          diagnosis.xpath('sdata:severity/text()').to_s.should == 'error'
          diagnosis.xpath('sdata:sdataCode/text()').to_s.should == 'ApplicationDiagnosis'
          diagnosis.xpath('sdata:message/text()').to_s.should == "Exception while trying to construct payload map"
          diagnosis.xpath('sdata:stackTrace/text()').to_s.include?('/diagnosis_spec.rb').should be_true
        end

        it "should correctly compose regular entry as well" do
          @controller.should_receive(:render) do |hash|
            successful_entry = hash[:xml].entries.select{ |e| e.diagnosis.nil? }.first
            successful_entry.id.should_not be_nil
            successful_entry.content.should_not be_nil
            successful_entry.sdata_payload.should_not be_nil
          end
          @controller.sdata_collection
        end
      end

      it "should construct multiple diagnosis elements within the same entry to describe multiple caught exceptions" do
        pending #not implemented, difficulties with rAtom
      end

      context "when feed is erroneous" do
        before :each do
          @controller.sdata_options[:model].stub! :all => [FeedDiagnosisCustomer.new, Customer.new]
          @controller.should_receive(:render) do |hash|
            @feed = hash[:xml]
          end
          @controller.sdata_collection
        end

        it "should still include healthy entry into response" do
          @feed.entries.size.should == 1

          failed_entry = @feed.entries.first
          failed_entry.id.should_not be_nil
          failed_entry.sdata_payload.should_not be_nil
          failed_entry.content.should_not be_nil
          failed_entry.diagnosis.should be_nil
        end

        it "should include feed diagnosis into response" do
          failed_entry = parse_xml(@feed.to_xml)
          feed_diagnoses = failed_entry.xpath('/xmlns:feed/sdata:diagnosis').first
          feed_diagnoses.children.size.should == 1
          diagnosis = feed_diagnoses.children.first

          diagnosis.xpath('sdata:severity/text()').to_s.should == 'error'
          diagnosis.xpath('sdata:sdataCode/text()').to_s.should == 'ApplicationDiagnosis'
          diagnosis.xpath('sdata:message/text()').to_s.should == "Exception while trying to get customer id"
          diagnosis.xpath('sdata:stackTrace').to_s.include?('/diagnosis_spec.rb').should == true
        end
      end

      context "when both feed and entry are erroneous" do
        before :each do
          @controller.sdata_options[:model].stub! :all => [FeedDiagnosisCustomer.new, FeedDiagnosisCustomer.new, EntryDiagnosisCustomer.new, Customer.new, Customer.new]
          @controller.should_receive(:render) do |hash|
            @feed = hash[:xml]
            @failed_entries = @feed.entries.reject{ |e| e.diagnosis.nil? }
            @successful_entries = @feed.entries.select { |e| e.diagnosis.nil? }
          end
          @controller.sdata_collection
        end

        it "should contain all three entries" do
          @feed.entries.size.should == 3

          @failed_entries.size.should == 1
          @successful_entries.size.should == 2
        end
        
        it "should compose entry diagnosis properly" do
          failed_entry = @failed_entries.first

          failed_entry.id.should_not be_nil
          failed_entry.content.should_not be_nil
          failed_entry.sdata_payload.should be_nil

          feed_xml = parse_xml(@feed.to_xml)
          diagnosis = feed_xml.xpath('//xmlns:entry/sdata:diagnosis').first
          diagnosis.xpath('sdata:severity/text()').to_s.should == 'error'
          diagnosis.xpath('sdata:sdataCode/text()').to_s.should == 'ApplicationDiagnosis'
          diagnosis.xpath('sdata:message/text()').to_s.should == "Exception while trying to construct payload map"
        end
        
        it "should compose healthy entries properly" do
          @successful_entries.each do |entry|
            entry.id.should_not be_nil
            entry.content.should_not be_nil
            entry.sdata_payload.should_not be_nil
          end
        end

        it "should contain feed diagnoses" do
          feed_xml = parse_xml(@feed.to_xml)

          feed_diagnoses = feed_xml.xpath('/xmlns:feed/sdata:diagnosis')
          feed_diagnoses.count.should == 2
          feed_diagnoses.each do |diagnosis|
            diagnosis.xpath('sdata:diagnosis/sdata:severity/text()').to_s.should == 'error'
            diagnosis.xpath('sdata:diagnosis/sdata:sdataCode/text()').to_s.should == 'ApplicationDiagnosis'
            diagnosis.xpath('sdata:diagnosis/sdata:message/text()').to_s.should == 'Exception while trying to get customer id'
          end
        end
      end

      context "when exception is raised at the action method leve" do
        before :each do
          @controller.stub!(:sdata_scope).and_raise(Exception.new('exception rendering collection'))
          @controller.should_receive(:render) do |hash|
            @feed = hash[:xml]
          end
          @controller.sdata_collection
        end

        it "should construct standalone exception with full xml header" do
          @feed.class.should == LibXML::XML::Document
          feed_xml = parse_xml(@feed.to_s)
          feed_xml.xpath('/sdata:diagnoses/sdata:diagnosis').count.should == 1
          diagnosis = feed_xml.xpath('/sdata:diagnoses/sdata:diagnosis').first
          diagnosis.xpath('./node()').map(&:name_with_ns).to_set.should == ["sdata:message", "sdata:sdataCode", "sdata:severity", "sdata:stackTrace"].to_set

          diagnosis.xpath("sdata:message/text()").to_s.should == "exception rendering collection"
          diagnosis.xpath("sdata:sdataCode/text()").to_s.should == "ApplicationDiagnosis"
          diagnosis.xpath("sdata:severity/text()").to_s.should == "error"
        end
      end
    end

    describe "given a controller which acts as sdata" do
      before :all do
        
        class NewBase < ActionController::Base
          extend ControllerMixin
          extend SData::ApplicationControllerMixin

          acts_as_sdata :model => Customer,
                        :feed => { :id => 'some-unique-id',
                                   :author => 'Test Author',
                                   :path => '/test_resource',
                                   :title => 'List of Test Items',
                                   :default_items_per_page => 10,
                                   :maximum_items_per_page => 100}

          sdata_rescue_support

          rescue_from Exception, :with => :global_rescue

          def global_rescue
            if request.env['REQUEST_URI'].match(/^\/sdata/)
              #this case must happen in ALL rails environments (dev, test, prod, etc.)
              sdata_global_rescue(exception, request.env['REQUEST_URI'])
            end
          end
        end
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