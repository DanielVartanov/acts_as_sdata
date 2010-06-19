require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe SData::ActiveRecordExtensions::Mixin, "#to_atom" do
  describe "given a class extended by ActiveRecordExtensions" do
    before :all do
      SData::SdUuid.extend SData::ActiveRecordExtensions::SdataUuidMixin
      SData::SdUuid.class_eval { acts_as_sdata_uuid }
      [User, Customer, Contact, Address].each do |model|
        model.extend SData::ActiveRecordExtensions::Mixin
        model.extend SData::ActiveRecordExtensions::SdataUuidableMixin
        model.class_eval { acts_as_sdata }
      end
      Customer.class_eval { has_sdata_uuid }
      Contact.class_eval { has_sdata_uuid }
    end

    def customer_attributes
      ["crmErp:address", "crmErp:associatedContacts", "crmErp:createdAt", "crmErp:hashValue", "crmErp:myContacts", "crmErp:myDefaultContact", "crmErp:name", "crmErp:number", "crmErp:simpleElements", "crmErp:updatedAt"].to_set
    end

    def contact_attributes
      ["crmErp:createdAt", "crmErp:customerId", "crmErp:name", "crmErp:updatedAt"].to_set
    end

    def payload_header_assertions(payload)
      payload.children.size.should == 1
      customer = payload.xpath('crmErp:customer').first
      customer.attributes_with_ns.keys.to_set.should == ["sdata:key", "sdata:url", "sdata:uuid"].to_set
      customer.attributes_with_ns["sdata:key"].should == "12345"
      customer.attributes_with_ns["sdata:url"].should == "http://www.example.com/sdata/example/myContract/myDataSet/customers('12345')"
      customer.attributes_with_ns["sdata:uuid"].should == 'CUST-10000'
    end

    describe "given the payload generating conditions" do
      before :each do
        Customer.extend SData::PayloadMap
        @customer = Customer.new.populate_defaults
        @customer.id = 12345
        @customer.contacts[0].id = 123
        @customer.contacts[1].id = 456
        @customer.contacts[1].name = "Second Contact Name"
        @customer.contacts.each do |contact|
          contact.populate_defaults
        end
        @customer.address.populate_defaults
      end

      def payload(options)
        xml = Nokogiri::XML(@customer.to_atom(options).to_xml) { |config| config.noblanks }
        xml.xpath('xmlns:entry/sdata:payload').first
      end

      it "describes elements with recursively included children without including association data" do
        payload = payload(:dataset => 'myDataSet', :include => '$children')

        payload_header_assertions(payload)

        customer = payload.xpath('crmErp:customer')
        customer.children.map(&:name_with_ns).to_set.should == customer_attributes
        customer.children.each do |element|
          case element.name_with_ns

          when 'crmErp:associatedContacts'
            element.attributes_with_ns.keys.should == ['sdata:url']
            element.attributes_with_ns['sdata:url'].should == "http://www.example.com/sdata/example/myContract/myDataSet/customer('12345')/associatedContacts"
            element.children.map(&:name_with_ns).to_set.should == ["crmErp:contact", "crmErp:contact"].to_set
            children = element.children.each do |child_element|
              case child_element.attributes_with_ns['sdata:key']
              when '123'
                child_element.attributes_with_ns.keys.to_set.should == ['sdata:key', 'sdata:url', 'sdata:uuid'].to_set
                child_element.attributes_with_ns['sdata:key'].should == "123"
                child_element.attributes_with_ns['sdata:url'].should == "http://www.example.com/sdata/example/myContract/myDataSet/contacts('123')"
                child_element.attributes_with_ns['sdata:uuid'].should == "C-123-456"
                child_element.children.should be_blank
              when '456'
                child_element.attributes_with_ns.keys.to_set.should == ['sdata:key', 'sdata:url'].to_set
                child_element.attributes_with_ns['sdata:key'].should == "456"
                child_element.attributes_with_ns['sdata:url'].should == "http://www.example.com/sdata/example/myContract/myDataSet/contacts('456')"
                child_element.children.should be_blank
              else
                raise "Unknown contact attribute: #{child_element.attributes_with_ns['sdata:key']}"
              end
            end
          when 'crmErp:simpleElements'
            element.children.map(&:name_with_ns).to_set.should == ["crmErp:simpleElement", "crmErp:simpleElement"].to_set
            element.xpath('crmErp:simpleElement/text()').map(&:to_s).should == ["element 1", "element 2"]
          when 'crmErp:hashValue'
            element.children.size.should == 1
            element.children[0].name_with_ns.should == "crmErp:simpleObjectKey"
            element.children[0].text.should == "simple_object_value"
          when 'crmErp:myContacts'

            element.attributes_with_ns.keys.should == ['sdata:url']
            element.attributes_with_ns['sdata:url'].should == "http://www.example.com/sdata/example/myContract/myDataSet/customer('12345')/myContacts"
            element.children.map(&:name_with_ns).to_set.should == ["crmErp:contact", "crmErp:contact"].to_set
            children = element.children.each do |child_element|
              case child_element.attributes_with_ns['sdata:key']
              when '123'
                child_element.attributes_with_ns.keys.to_set.should == ['sdata:key', 'sdata:url', 'sdata:uuid'].to_set
                child_element.attributes_with_ns['sdata:key'].should == "123"
                child_element.attributes_with_ns['sdata:url'].should == "http://www.example.com/sdata/example/myContract/myDataSet/contacts('123')"
                child_element.attributes_with_ns['sdata:uuid'].should == "C-123-456"
                child_element.children.map(&:name_with_ns).to_set.should == contact_attributes
                child_element.children.each do |grandchild_element|
                case grandchild_element.name_with_ns
                  when "crmErp:createdAt"
                    Time.parse(grandchild_element.text).should < Time.now-2.days                
                  when "crmErp:name"
                    grandchild_element.attributes_with_ns["xsi:nil"].should == nil
                    grandchild_element.text.should == "Contact Name"                 
                  when "crmErp:customerId"
                    grandchild_element.attributes_with_ns["xsi:nil"].should == 'true'
                  when "crmErp:updatedAt"
                    Time.parse(grandchild_element.text).should < Time.now-1.day   
                  else
                    raise "Unknown contact element: #{grandchild_element.name_with_ns}"
                  end
                end
              when '456'
                child_element.attributes_with_ns.keys.to_set.should == ['sdata:key', 'sdata:url'].to_set
                child_element.attributes_with_ns['sdata:key'].should == "456"
                child_element.attributes_with_ns['sdata:url'].should == "http://www.example.com/sdata/example/myContract/myDataSet/contacts('456')"
                child_element.children.map(&:name_with_ns).to_set.should == contact_attributes
                child_element.children.each do |grandchild_element|
                case grandchild_element.name_with_ns
                  when "crmErp:createdAt"
                    Time.parse(grandchild_element.text).should < Time.now-2.days                
                  when "crmErp:name"
                    grandchild_element.attributes_with_ns["xsi:nil"].should == nil
                    grandchild_element.text.should == "Second Contact Name"                 
                  when "crmErp:customerId"
                    grandchild_element.attributes_with_ns["xsi:nil"].should == 'true'
                  when "crmErp:updatedAt"
                    Time.parse(child_element.text).should < Time.now-1.day   
                  else
                    raise "Unknown contact element: #{grandchild_element.name_with_ns}"
                  end
                end
              else
                raise "Unknown contact attribute: #{child_element.attributes_with_ns['sdata:key']}"
              end
            end
          when 'crmErp:myDefaultContact'
            element.attributes_with_ns["sdata:key"].should == "123"
            element.attributes_with_ns["sdata:url"].should == "http://www.example.com/sdata/example/myContract/myDataSet/contacts('123')"
            element.children.map(&:name_with_ns).to_set.should == contact_attributes
            element.children.each do |child_element|
              case child_element.name_with_ns
              when "crmErp:createdAt"
                Time.parse(child_element.text).should < Time.now-2.days                
              when "crmErp:name"
                child_element.text.should == "Contact Name"                 
              when "crmErp:customerId"
                child_element.attributes_with_ns["xsi:nil"].should == 'true'
              when "crmErp:updatedAt"
                Time.parse(child_element.text).should < Time.now-1.day
              when "crmErp:id"
                element.text.should_not be_nil
              else
                raise "Unknown contact element: #{child_element.name_with_ns}"
              end
            end
          when 'crmErp:address'
            element.attributes_with_ns["sdata:key"].should == "12345"
            element.attributes_with_ns["sdata:url"].should == "http://www.example.com/sdata/example/myContract/myDataSet/addresses('12345')"
            element.children.each do |child_element|
              case child_element.name_with_ns
              when "crmErp:createdAt"
                Time.parse(child_element.text).should < Time.now-2.days                
              when "crmErp:customerId"
                child_element.attributes_with_ns["xsi:nil"].should == 'true'
              when "crmErp:updatedAt"
                Time.parse(child_element.text).should < Time.now-1.day   
              when "crmErp:city"
                child_element.text.should == 'Vancouver'
              else
                raise "Unknown address element: #{child_element.name_with_ns}"
              end
            end
          when 'crmErp:name'
            element.text.should == "Customer Name"
          when 'crmErp:number'
            element.text.should == "12345"          
          when "crmErp:createdAt"
             Time.parse(element.text).should < Time.now-2.days        
          when "crmErp:updatedAt"
             Time.parse(element.text).should < Time.now-1.days 
          else
            raise "Unexpected customer element: #{element.name_with_ns}"
          end
        end
      end

      it "describes elements with recursively included children without including association data when in sync mode" do
        payload = payload(:dataset => 'myDataSet', :sync => 'true')

        payload_header_assertions(payload)

        customer = payload.xpath('crmErp:customer')
        customer.children.map(&:name_with_ns).to_set.should == customer_attributes
        customer.children.each do |element|
          case element.name_with_ns

          when 'crmErp:associatedContacts'
            element.attributes_with_ns.keys.should == ['sdata:url']
            element.attributes_with_ns['sdata:url'].should == "http://www.example.com/sdata/example/myContract/myDataSet/customer('12345')/associatedContacts"
            element.children.map(&:name_with_ns).to_set.should == ["crmErp:contact", "crmErp:contact"].to_set
            children = element.children.each do |child_element|
              case child_element.attributes_with_ns['sdata:key']
              when '123'
                child_element.attributes_with_ns.keys.to_set.should == ['sdata:key', 'sdata:url', 'sdata:uuid'].to_set
                child_element.attributes_with_ns['sdata:key'].should == "123"
                child_element.attributes_with_ns['sdata:url'].should == "http://www.example.com/sdata/example/myContract/myDataSet/contacts('123')"
                child_element.attributes_with_ns['sdata:uuid'].should == "C-123-456"
                child_element.children.should be_blank
              when '456'
                child_element.attributes_with_ns.keys.to_set.should == ['sdata:key', 'sdata:url'].to_set
                child_element.attributes_with_ns['sdata:key'].should == "456"
                child_element.attributes_with_ns['sdata:url'].should == "http://www.example.com/sdata/example/myContract/myDataSet/contacts('456')"
                child_element.children.should be_blank
              else
                raise "Unknown contact attribute: #{child_element.attributes_with_ns['sdata:key']}"
              end
            end
          when 'crmErp:simpleElements'
            element.children.map(&:name_with_ns).to_set.should == ["crmErp:simpleElement", "crmErp:simpleElement"].to_set
            element.xpath('crmErp:simpleElement/text()').map(&:to_s).should == ["element 1", "element 2"]
          when 'crmErp:hashValue'
            element.children.size.should == 1
            element.children[0].name_with_ns.should == "crmErp:simpleObjectKey"
            element.children[0].text.should == "simple_object_value"
          when 'crmErp:myContacts'
            element.attributes_with_ns.keys.should == ['sdata:url']
            element.attributes_with_ns['sdata:url'].should == "http://www.example.com/sdata/example/myContract/myDataSet/customer('12345')/myContacts"
            element.children.map(&:name_with_ns).to_set.should == ["crmErp:contact", "crmErp:contact"].to_set
            children = element.children.each do |child_element|
              case child_element.attributes_with_ns['sdata:key']
              when '123'
                child_element.attributes_with_ns.keys.to_set.should == ['sdata:key', 'sdata:url', 'sdata:uuid'].to_set
                child_element.attributes_with_ns['sdata:key'].should == "123"
                child_element.attributes_with_ns['sdata:url'].should == "http://www.example.com/sdata/example/myContract/myDataSet/contacts('123')"
                child_element.attributes_with_ns['sdata:uuid'].should == "C-123-456"
                child_element.children.map(&:name_with_ns).to_set.should == contact_attributes
                child_element.children.each do |grandchild_element|
                case grandchild_element.name_with_ns
                  when "crmErp:createdAt"
                    Time.parse(grandchild_element.text).should < Time.now-2.days                
                  when "crmErp:name"
                    grandchild_element.attributes_with_ns["xsi:nil"].should == nil
                    grandchild_element.text.should == "Contact Name"                 
                  when "crmErp:customerId"
                    grandchild_element.attributes_with_ns["xsi:nil"].should == 'true'
                  when "crmErp:updatedAt"
                    Time.parse(grandchild_element.text).should < Time.now-1.day   
                  else
                    raise "Unknown contact element: #{grandchild_element.name_with_ns}"
                  end
                end
              when '456'
                child_element.attributes_with_ns.keys.to_set.should == ['sdata:key', 'sdata:url'].to_set
                child_element.attributes_with_ns['sdata:key'].should == "456"
                child_element.attributes_with_ns['sdata:url'].should == "http://www.example.com/sdata/example/myContract/myDataSet/contacts('456')"
                child_element.children.map(&:name_with_ns).to_set.should == contact_attributes
                child_element.children.each do |grandchild_element|
                case grandchild_element.name_with_ns
                  when "crmErp:createdAt"
                    Time.parse(grandchild_element.text).should < Time.now-2.days                
                  when "crmErp:name"
                    grandchild_element.attributes_with_ns["xsi:nil"].should == nil
                    grandchild_element.text.should == "Second Contact Name"                 
                  when "crmErp:customerId"
                    grandchild_element.attributes_with_ns["xsi:nil"].should == 'true'
                  when "crmErp:updatedAt"
                    Time.parse(child_element.text).should < Time.now-1.day   
                  else
                    raise "Unknown contact element: #{grandchild_element.name_with_ns}"
                  end
                end
              else
                raise "Unknown contact attribute: #{child_element.attributes_with_ns['sdata:key']}"
              end
            end
          when 'crmErp:myDefaultContact'
            element.attributes_with_ns["sdata:key"].should == "123"
            element.attributes_with_ns["sdata:url"].should == "http://www.example.com/sdata/example/myContract/myDataSet/contacts('123')"
            element.children.map(&:name_with_ns).to_set.should == contact_attributes
            element.children.each do |child_element|
              case child_element.name_with_ns
              when "crmErp:createdAt"
                Time.parse(child_element.text).should < Time.now-2.days                
              when "crmErp:name"
                child_element.text.should == "Contact Name"                 
              when "crmErp:customerId"
                child_element.attributes_with_ns["xsi:nil"].should == 'true'
              when "crmErp:updatedAt"
                Time.parse(child_element.text).should < Time.now-1.day
              when "crmErp:id"
                element.text.should_not be_nil
              else
                raise "Unknown contact element: #{child_element.name_with_ns}"
              end
            end
          when 'crmErp:address'
            element.attributes_with_ns["sdata:key"].should == "12345"
            element.attributes_with_ns["sdata:url"].should == "http://www.example.com/sdata/example/myContract/myDataSet/addresses('12345')"
            element.children.each do |child_element|
              case child_element.name_with_ns
              when "crmErp:createdAt"
                Time.parse(child_element.text).should < Time.now-2.days                
              when "crmErp:customerId"
                child_element.attributes_with_ns["xsi:nil"].should == 'true'
              when "crmErp:updatedAt"
                Time.parse(child_element.text).should < Time.now-1.day   
              when "crmErp:city"
                child_element.text.should == 'Vancouver'
              else
                raise "Unknown address element: #{child_element.name_with_ns}"
              end
            end
          when 'crmErp:name'
            element.text.should == "Customer Name"
          when 'crmErp:number'
            element.text.should == "12345"          
          when "crmErp:createdAt"
             Time.parse(element.text).should < Time.now-2.days        
          when "crmErp:updatedAt"
             Time.parse(element.text).should < Time.now-1.days 
          else
            raise "Unexpected customer element: #{element.name_with_ns}"
          end
        end
      end

      it "describes elements with immediate children only" do
        payload = payload(:dataset => 'myDataSet')

        payload_header_assertions(payload)
        customer = payload.xpath('crmErp:customer')
        customer.children.map(&:name_with_ns).to_set.should == customer_attributes
        customer.children.each do |element|
          case element.name_with_ns
          when 'crmErp:associatedContacts'
            element.attributes_with_ns.keys.should == ['sdata:url']
            element.attributes_with_ns['sdata:url'].should == "http://www.example.com/sdata/example/myContract/myDataSet/customer('12345')/associatedContacts"
            element.children.map(&:name_with_ns).to_set.should == ["crmErp:contact", "crmErp:contact"].to_set
            children = element.children.each do |child_element|
              case child_element.attributes_with_ns['sdata:key']
              when '123'
                child_element.attributes_with_ns.keys.to_set.should == ['sdata:key', 'sdata:url', 'sdata:uuid'].to_set
                child_element.attributes_with_ns['sdata:key'].should == "123"
                child_element.attributes_with_ns['sdata:url'].should == "http://www.example.com/sdata/example/myContract/myDataSet/contacts('123')"
                child_element.attributes_with_ns['sdata:uuid'].should == "C-123-456"
                child_element.children.should be_blank
              when '456'
                child_element.attributes_with_ns.keys.to_set.should == ['sdata:key', 'sdata:url'].to_set
                child_element.attributes_with_ns['sdata:key'].should == "456"
                child_element.attributes_with_ns['sdata:url'].should == "http://www.example.com/sdata/example/myContract/myDataSet/contacts('456')"
                child_element.children.should be_blank
              else
                raise "Unknown contact attribute: #{child_element.attributes_with_ns['sdata:key']}"
              end
            end
          when 'crmErp:simpleElements'
            element.children.map(&:name_with_ns).to_set.should == ["crmErp:simpleElement", "crmErp:simpleElement"].to_set
            element.xpath('crmErp:simpleElement/text()').map(&:to_s).should == ["element 1", "element 2"]
          when 'crmErp:hashValue'
            element.children.size.should == 1
            element.children[0].name_with_ns.should == "crmErp:simpleObjectKey"
            element.children[0].text.should == "simple_object_value"
          when 'crmErp:myContacts'
            element.attributes_with_ns.keys.should == ['sdata:url']
            element.attributes_with_ns['sdata:url'].should == "http://www.example.com/sdata/example/myContract/myDataSet/customer('12345')/myContacts"
            element.attributes_with_ns.keys.should == ['sdata:url']
            element.attributes_with_ns['sdata:url'].should == "http://www.example.com/sdata/example/myContract/myDataSet/customer('12345')/myContacts"
            element.children.map(&:name_with_ns).to_set.should == ["crmErp:contact", "crmErp:contact"].to_set
            children = element.children.each do |child_element|
              case child_element.attributes_with_ns['sdata:key']
              when '123'
                child_element.attributes_with_ns.keys.to_set.should == ['sdata:key', 'sdata:url', 'sdata:uuid'].to_set
                child_element.attributes_with_ns['sdata:key'].should == "123"
                child_element.attributes_with_ns['sdata:url'].should == "http://www.example.com/sdata/example/myContract/myDataSet/contacts('123')"
                child_element.attributes_with_ns['sdata:uuid'].should == "C-123-456"
                child_element.children.should be_blank
              when '456'
                child_element.attributes_with_ns.keys.to_set.should == ['sdata:key', 'sdata:url'].to_set
                child_element.attributes_with_ns['sdata:key'].should == "456"
                child_element.attributes_with_ns['sdata:url'].should == "http://www.example.com/sdata/example/myContract/myDataSet/contacts('456')"
                child_element.children.should be_blank
              else
                raise "Unknown contact attribute: #{child_element.attributes_with_ns['sdata:key']}"
              end
            end
          when 'crmErp:myDefaultContact'
            element.attributes_with_ns["sdata:key"].should == "123"
            element.attributes_with_ns["sdata:url"].should == "http://www.example.com/sdata/example/myContract/myDataSet/contacts('123')"
            element.children.size.should == 0
          when 'crmErp:name'
            element.text.should == "Customer Name"
          when 'crmErp:number'
            element.text.should == "12345"          
          when "crmErp:createdAt"
             Time.parse(element.text).should < Time.now-2.days        
          when "crmErp:updatedAt"
             Time.parse(element.text).should < Time.now-1.days 
          when 'crmErp:address'
            element.attributes_with_ns["sdata:key"].should == "12345"
            element.attributes_with_ns["sdata:url"].should == "http://www.example.com/sdata/example/myContract/myDataSet/addresses('12345')"

            element.children.each do |child_element|
              case child_element.name_with_ns
              when "crmErp:createdAt"
                Time.parse(child_element.text).should < Time.now-2.days                
              when "crmErp:customerId"
                child_element.attributes_with_ns["xsi:nil"].should == 'true'
              when "crmErp:updatedAt"
                Time.parse(child_element.text).should < Time.now-1.day   
              when "crmErp:city"
                child_element.text.should == 'Vancouver'
              else
                raise "Unknown address element: #{child_element.name_with_ns}"
              end
            end
          else
            raise "Unexpected customer element: #{element.name_with_ns}"
          end
        end
      end

      it "shows no payload at all with precedence 0" do
        payload = payload(:dataset => 'myDataSet', :precedence => 0)

        payload.should be_nil
      end
      
      it "shows header info only with precedence 1" do
        payload = payload(:dataset => 'myDataSet', :precedence => 1)

        payload_header_assertions(payload)
        customer = payload.xpath('crmErp:customer').first
        customer.children.size.should == 0
      end

      it "shows no uuid if match is not found" do
        @customer.id = 4321
        payload = payload(:dataset => 'myDataSet', :precedence => 1)

        customer = payload.xpath('crmErp:customer').first
        customer.attributes_with_ns.keys.to_set.should == ["sdata:key", "sdata:url"].to_set
        customer.children.size.should == 0
      end

      it "shows only some attributes with precedence 2" do
        payload = payload(:dataset => 'myDataSet', :precedence => 2)

        payload_header_assertions(payload)

        customer = payload.xpath('crmErp:customer').first
        customer.children.map(&:name_with_ns).to_set.should == ["crmErp:name"].to_set
        customer.children.each do |element|
          case element.name_with_ns
          when 'crmErp:name'
            element.text.should == "Customer Name"
          when "crmErp:id"
            element.text.should_not be_nil
          else
            raise "Unexpected customer element: #{element.name_with_ns}"
          end
        end
      end

      it "applies precendence filter to child attributes as well" do
        payload = payload(:dataset => 'myDataSet', :include => "$children", :precedence => 3)

        payload_header_assertions(payload)
        customer = payload.xpath('crmErp:customer').first
        customer.children.map(&:name_with_ns).to_set.should == ["crmErp:associatedContacts", "crmErp:createdAt", "crmErp:myDefaultContact", "crmErp:name", "crmErp:updatedAt"].to_set
        customer.children.each do |element|
          case element.name_with_ns
          when 'crmErp:associatedContacts'
            element.attributes_with_ns.keys.should == ['sdata:url']
            element.attributes_with_ns['sdata:url'].should == "http://www.example.com/sdata/example/myContract/myDataSet/customer('12345')/associatedContacts"
            element.children.map(&:name_with_ns).to_set.should == ["crmErp:contact", "crmErp:contact"].to_set
            children = element.children.each do |child_element|
              case child_element.attributes_with_ns['sdata:key']
              when '123'
                child_element.attributes_with_ns.keys.to_set.should == ['sdata:key', 'sdata:url', 'sdata:uuid'].to_set
                child_element.attributes_with_ns['sdata:key'].should == "123"
                child_element.attributes_with_ns['sdata:url'].should == "http://www.example.com/sdata/example/myContract/myDataSet/contacts('123')"
                child_element.attributes_with_ns['sdata:uuid'].should == "C-123-456"
                child_element.children.should be_blank
              when '456'
                child_element.attributes_with_ns.keys.to_set.should == ['sdata:key', 'sdata:url'].to_set
                child_element.attributes_with_ns['sdata:key'].should == "456"
                child_element.attributes_with_ns['sdata:url'].should == "http://www.example.com/sdata/example/myContract/myDataSet/contacts('456')"
                child_element.children.should be_blank
              else
                raise "Unknown contact attribute: #{child_element.attributes_with_ns['sdata:key']}"
              end
            end
          when 'crmErp:name'
            element.text.should == "Customer Name"
          when "crmErp:createdAt"
             Time.parse(element.text).should < Time.now-2.days        
          when "crmErp:updatedAt"
             Time.parse(element.text).should < Time.now-1.days
          when 'crmErp:myDefaultContact'
            element.attributes_with_ns["sdata:key"].should == "123"
            element.attributes_with_ns["sdata:url"].should == "http://www.example.com/sdata/example/myContract/myDataSet/contacts('123')"
            element.children.map(&:name_with_ns).to_set.should == ["crmErp:customerId", "crmErp:name"].to_set
            element.children.each do |child_element|
              case child_element.name_with_ns
              when "crmErp:name"
                child_element.text.should == "Contact Name"                   
              when "crmErp:customerId"
                child_element.attributes_with_ns["xsi:nil"].should == 'true'
              when "crmErp:id"
                element.text.should_not be_nil
              else
                raise "Unknown contact element: #{child_element.name_with_ns}"
              end
            end
          when "crmErp:id"
            element.text.should_not be_nil
          else
            raise "Unexpected customer element: #{element.name_with_ns}"
          end
        end
      end

      it "shows custom content and descriptor fields when requested" do
        Customer.class_eval { acts_as_sdata(:content => :sdata_content) }
        Contact.class_eval { acts_as_sdata(:content => :sdata_content) }

        payload = payload(:dataset => 'myDataSet', :include => "$descriptor,$children")

        payload.children.size.should == 1
        customer = payload.xpath('crmErp:customer').first
        customer.name_with_ns.should == 'crmErp:customer'
        customer.attributes_with_ns.keys.to_set.should == ["sdata:descriptor", "sdata:key", "sdata:url", "sdata:uuid"].to_set
        customer.attributes_with_ns["sdata:key"].should == "12345"
        customer.attributes_with_ns["sdata:url"].should == "http://www.example.com/sdata/example/myContract/myDataSet/customers('12345')"
        customer.attributes_with_ns["sdata:descriptor"].should == "Customer #12345: Customer Name"
        customer.children.each do |element|
          case element.name_with_ns
          when 'crmErp:myDefaultContact'
            element.attributes_with_ns.keys.to_set.should == ["sdata:descriptor", "sdata:key", "sdata:url", "sdata:uuid"].to_set
            element.attributes_with_ns['sdata:descriptor'].should == "Contact #123: Contact Name"
          when 'crmErp:myContacts'
            found_with_uuid, found_without_uuid = false
            element.children.size.should == 2
            element.children.each do |child_element|
              if child_element.attributes_with_ns['sdata:uuid']
                found_with_uuid = true
                child_element.attributes_with_ns.keys.to_set.should == ["sdata:descriptor", "sdata:key", "sdata:url", "sdata:uuid"].to_set
                child_element.attributes_with_ns['sdata:uuid'].should == "C-123-456"
              else
                found_without_uuid = true
                child_element.attributes_with_ns.keys.to_set.should == ["sdata:descriptor", "sdata:key", "sdata:url"].to_set
              end
              child_element.attributes_with_ns['sdata:descriptor'].should =~ /Contact ##{child_element.attributes_with_ns['sdata:key']}.*/
            end
            found_with_uuid.should == true
            found_without_uuid.should == true
          end
        end
      end
      
      it "makes include=something_other_than_$children_or_$descriptor do absolutely nothing until we implement the algorithm properly" do
        [true, false].each do |bool|
          SData::Payload.stub :is_sync? => bool
          payload_1 = payload(:dataset => 'myDataSet')
          payload_2 = payload(:dataset => 'myDataSet', :include => 'associatedContacts')
          payload_3 = payload(:dataset => 'myDataSet', :include => 'myContacts')
          payload_1.to_xml.should == payload_2.to_xml
          payload_1.to_xml.should == payload_3.to_xml          
        end
      end
      
      it "includes associations on nested include request for that association and properly parses nesting levels" do
        # ?include='child/grandchild' should find and include the child, then traverse thru child attributes
        # and find the grandchild, to include it too.
        # But it should not search for or include 'grandchild' association (or any other association except
        # 'child') from outside of the child's tree, nor should it search for or include 'child' association 
        # (or any other association) from inside the child's tree.
        pending # Not due June 1
      end
      
      it "only shows requested attributes when a simple select parameter is given" do
        payload = payload(:dataset => 'myDataSet', :select => 'name,number')

        payload_header_assertions(payload)
        customer = payload.xpath('crmErp:customer').first
        customer.children.map(&:name_with_ns).to_set.should == ['crmErp:name', 'crmErp:number'].to_set
        customer.children.each do |element|
          case element.name_with_ns
          when 'crmErp:name'
            element.text.should == "Customer Name"
          when 'crmErp:number'
            element.text.should == "12345"          
          else
            raise "Unexpected customer element: #{element.name_with_ns}"
          end
        end
      end

      it "only shows requested attributes when a nested select parameter is given and properly parses nesting level" do
        pending # Not due June 1
      end
      
      it "properly escapes xml content in user data" do
        Customer.class_eval { acts_as_sdata(:content => :sdata_content) }
        Contact.class_eval { acts_as_sdata(:content => :sdata_content) }
        @customer.name = "</crmErp:name><div>asdf</div>"
        @customer.number = "<div>123456</div>"
        @customer.to_atom(:dataset => 'myDataSet').sdata_payload.to_xml.to_s.include?("</crmErp:name><div>asdf</div>").should == false
        @customer.to_atom(:dataset => 'myDataSet').sdata_payload.to_xml.to_s.include?("<div>123456</div>").should == false
        @customer.to_atom(:dataset => 'myDataSet').sdata_payload.to_xml.to_s.include?("&lt;/crmErp:name&gt;&lt;div&gt;asdf&lt;/div&gt;").should == true
        @customer.to_atom(:dataset => 'myDataSet').sdata_payload.to_xml.to_s.include?("&lt;div&gt;123456&lt;/div&gt;").should == true
      end  
    end
  end
end