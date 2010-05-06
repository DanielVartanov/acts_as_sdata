require File.join(File.dirname(__FILE__), '..', 'spec_helper')
                                                          
include SData

describe ActiveRecordMixin, "#to_atom" do
  describe "given a class extended by ActiveRecordExtentions" do
    before :all do
      [User, Customer, Contact].each do |model|
        model.extend ActiveRecordMixin
        model.class_eval { acts_as_sdata }
      end
    end

    def customer_attributes
      ["crmErp:createdAt", "crmErp:hash", "crmErp:myContacts", "crmErp:myDefaultContact", "crmErp:name", "crmErp:number", "crmErp:simpleElements", "crmErp:updatedAt", "crmErp:uuid"]
    end

    def contact_attributes
      ["crmErp:createdAt", "crmErp:customerId", "crmErp:name", "crmErp:updatedAt", "crmErp:uuid"]
    end

    def payload_header_assertions(xml)
      xml.children.size.should == 1
      xml.children[0].name.should == 'crmErp:customer'
      xml.children[0].attributes.collect{|x|x[0]}.sort.should == ["sdata:key", "sdata:url", "sdata:uuid"]
      xml.children[0].attributes["sdata:key"].value.should == "12345"
      xml.children[0].attributes["sdata:url"].value.should == "http://www.example.com/sdata/example/myContract/-/customers('12345')"
      xml.children[0].attributes["sdata:uuid"].value.length.should > 0
    end
    describe "given the payload generating conditions" do
      before :each do 
        @customer = Customer.new.populate_defaults
        @customer.id = 12345
        @customer.contacts[0].id = 123
        @customer.contacts[0].uuid = 'C-123-456'
        @customer.contacts[1].id = 456
        @customer.contacts[1].name = "Second Contact Name"
        @customer.contacts.each do |contact|
          contact.populate_defaults
        end        
      end
      it "describes elements with recursively included children" do
        xml = Nokogiri::XML(@customer.to_atom(:include => '$children').payload.to_s)
        payload_header_assertions(xml)
        xml.children[0].children.collect{|x|x.name}.sort.should == customer_attributes
        xml.children[0].children.each do |element|
          case element.name
          when 'crmErp:simpleElements'
            element.children.collect{|x|x.name}.sort.should == ["crmErp:simpleElement", "crmErp:simpleElement"]
            [element.children[0].text, element.children[1].text].sort.should == ["element 1", "element 2"]
          when 'crmErp:hash'
            element.children.size.should == 1
            element.children[0].name.should == "crmErp:simpleObjectKey"
            element.children[0].text.should == "simple_object_value"
          when 'crmErp:myContacts'
            element.keys.should == ['sdata:url']
            element.attributes['sdata:url'].value.should == "http://www.example.com/sdata/example/myContract/-/customer('12345')/contacts"
            element.children.collect{|x|x.name}.sort.should == ["crmErp:myContact", "crmErp:myContact"]
            children = element.children.each do |child_element|
              case child_element.attributes['sdata:key'].value
              when '123'
                child_element.attributes['sdata:url'].value.should == "http://www.example.com/sdata/example/myContract/-/contacts('123')"
                child_element.children.collect{|x|x.name}.sort.should == contact_attributes
                child_element.children.each do |grandchild_element|
                case grandchild_element.name
                  when "crmErp:createdAt"
                    Time.parse(grandchild_element.text).should < Time.now-2.days                
                  when "crmErp:name"
                    grandchild_element.attributes["xsi:nil"].should == nil
                    grandchild_element.text.should == "Contact Name"                 
                  when "crmErp:customerId"
                    grandchild_element.attributes["xsi:nil"].value.should == 'true'               
                  when "crmErp:updatedAt"
                    Time.parse(grandchild_element.text).should < Time.now-1.day   
                  when "crmErp:uuid"
                    grandchild_element.attributes["xsi:nil"].should == nil
                    grandchild_element.text.should == 'C-123-456'
                  else
                    raise "Unknown contact element: #{grandchild_element.name}"
                  end
                end
              when '456'
                child_element.attributes['sdata:url'].value.should == "http://www.example.com/sdata/example/myContract/-/contacts('456')"
                child_element.children.collect{|x|x.name}.sort.should == contact_attributes
                child_element.children.each do |grandchild_element|
                case grandchild_element.name
                  when "crmErp:createdAt"
                    Time.parse(grandchild_element.text).should < Time.now-2.days                
                  when "crmErp:name"
                    grandchild_element.attributes["xsi:nil"].should == nil
                    grandchild_element.text.should == "Second Contact Name"                 
                  when "crmErp:customerId"
                    grandchild_element.attributes["xsi:nil"].value.should == 'true'               
                  when "crmErp:updatedAt"
                    Time.parse(child_element.text).should < Time.now-1.day   
                  when "crmErp:uuid"
                     grandchild_element.attributes["xsi:nil"].value.should == 'true'
                  else
                    raise "Unknown contact element: #{grandchild_element.name}"
                  end
                end
              else
                raise "Unknown contact attribute: #{child_element.attributes['sdata:key'].value}"
              end
            end
          when 'crmErp:myDefaultContact'
            element.attributes["sdata:key"].value.should == "123"
            element.attributes["sdata:url"].value.should == "http://www.example.com/sdata/example/myContract/-/contacts('123')"
            element.children.collect{|x|x.name}.sort.should == contact_attributes
            element.children.each do |child_element|
              case child_element.name
              when "crmErp:createdAt"
                Time.parse(child_element.text).should < Time.now-2.days                
              when "crmErp:name"
                child_element.text.should == "Contact Name"                 
              when "crmErp:customerId"
                child_element.attributes["xsi:nil"].value.should == 'true'               
              when "crmErp:updatedAt"
                Time.parse(child_element.text).should < Time.now-1.day   
              when "crmErp:uuid"
                child_element.attributes["xsi:nil"].should == nil
                child_element.text.should == 'C-123-456'
              else
                raise "Unknown contact element: #{child_element.name}"
              end
            end
          when 'crmErp:name'
            element.text.should == "Customer Name"
          when 'crmErp:number'
            element.text.should == "12345"          
          when 'crmErp:uuid'
            element.text.should == "CUST-123456-654321-000000"
          when "crmErp:createdAt"
             Time.parse(element.text).should < Time.now-2.days        
          when "crmErp:updatedAt"
             Time.parse(element.text).should < Time.now-1.days 
          else
            raise "Unknown customer element: #{element.name}"
          end
        end
      end
      
      it "describes elements with immediate children only" do
        xml = Nokogiri::XML(@customer.to_atom.payload.to_s)
        payload_header_assertions(xml)
        xml.children[0].children.collect{|x|x.name}.sort.should == customer_attributes      
        xml.children[0].children.each do |element|
          case element.name
          when 'crmErp:simpleElements'
            element.children.collect{|x|x.name}.sort.should == ["crmErp:simpleElement", "crmErp:simpleElement"]
            [element.children[0].text, element.children[1].text].sort.should == ["element 1", "element 2"]
          when 'crmErp:hash'
            element.children.size.should == 1
            element.children[0].name.should == "crmErp:simpleObjectKey"
            element.children[0].text.should == "simple_object_value"
          when 'crmErp:myContacts'
            element.keys.should == ['sdata:url']
            element.attributes['sdata:url'].value.should == "http://www.example.com/sdata/example/myContract/-/customer('12345')/contacts"
            element.children.size.should == 0
          when 'crmErp:myDefaultContact'
            element.attributes["sdata:key"].value.should == "123"
            element.attributes["sdata:url"].value.should == "http://www.example.com/sdata/example/myContract/-/contacts('123')"
            element.children.size.should == 0
          when 'crmErp:name'
            element.text.should == "Customer Name"
          when 'crmErp:number'
            element.text.should == "12345"          
          when "crmErp:createdAt"
             Time.parse(element.text).should < Time.now-2.days        
          when "crmErp:updatedAt"
             Time.parse(element.text).should < Time.now-1.days 
          when 'crmErp:uuid'
            element.text.should == "CUST-123456-654321-000000"
          else
            raise "Unknown customer element: #{element.name}"
          end
        end
      end

      it "shows no payload at all with precedence 0" do
        xml = Nokogiri::XML(@customer.to_atom(:precedence => 0).payload.to_s)
        xml.children.size.should == 0
      end
      
      it "shows header info only with precedence 1" do
        xml = Nokogiri::XML(@customer.to_atom(:precedence => 1).payload.to_s)
        payload_header_assertions(xml)
        xml.children[0].children.size.should == 0
      end

      it "shows only some attributes with precedence 2" do
        xml = Nokogiri::XML(@customer.to_atom(:precedence => 2).payload.to_s)
        payload_header_assertions(xml)
        xml.children[0].children.collect{|x|x.name}.sort.should == ["crmErp:name", "crmErp:uuid"]
        xml.children[0].children.each do |element|
          case element.name
          when 'crmErp:name'
            element.text.should == "Customer Name"
          when 'crmErp:uuid'
            element.text.should == "CUST-123456-654321-000000"
          else
            raise "Unknown customer element: #{element.name}"
          end
        end
      end

     it "applies precendence filter to child attributes as well" do
        xml = Nokogiri::XML(@customer.to_atom(:include => "$children", :precedence => 3).payload.to_s)
        payload_header_assertions(xml)
        xml.children[0].children.collect{|x|x.name}.sort.should == ["crmErp:createdAt", "crmErp:myDefaultContact", "crmErp:name", "crmErp:updatedAt", "crmErp:uuid"]
        xml.children[0].children.each do |element|
          case element.name
          when 'crmErp:name'
            element.text.should == "Customer Name"
          when "crmErp:createdAt"
             Time.parse(element.text).should < Time.now-2.days        
          when "crmErp:updatedAt"
             Time.parse(element.text).should < Time.now-1.days
          when 'crmErp:uuid'
            element.text.should == "CUST-123456-654321-000000"
          when 'crmErp:myDefaultContact'
            element.attributes["sdata:key"].value.should == "123"
            element.attributes["sdata:url"].value.should == "http://www.example.com/sdata/example/myContract/-/contacts('123')"
            element.children.collect{|x|x.name}.sort.should == ["crmErp:customerId", "crmErp:name", "crmErp:uuid"]
            element.children.each do |child_element|
              case child_element.name
              when "crmErp:name"
                child_element.text.should == "Contact Name"                   
              when "crmErp:uuid"
                child_element.attributes["xsi:nil"].should == nil
                child_element.text.should == 'C-123-456'
              when "crmErp:customerId"
                child_element.attributes["xsi:nil"].value.should == 'true'     
              else
                raise "Unknown contact element: #{child_element.name}"
              end
            end            
          else
            raise "Unknown customer element: #{element.name}"
          end
        end
      end

      it "shows custom content and descriptor fields when requested" do
        Customer.class_eval { acts_as_sdata(:content => :sdata_content) }
        Contact.class_eval { acts_as_sdata(:content => :sdata_content) }
        xml = Nokogiri::XML(@customer.to_atom(:include => "$descriptor,$children").payload.to_s)
        xml.children.size.should == 1
        xml.children[0].name.should == 'crmErp:customer'
        xml.children[0].attributes.collect{|x|x[0]}.sort.should == ["sdata:descriptor", "sdata:key", "sdata:url", "sdata:uuid"]
        xml.children[0].attributes["sdata:key"].value.should == "12345"
        xml.children[0].attributes["sdata:url"].value.should == "http://www.example.com/sdata/example/myContract/-/customers('12345')"
        xml.children[0].attributes["sdata:descriptor"].value.should == "Customer #12345: Customer Name"
        xml.children[0].children.each do |element|
          case element.name
          when 'crmErp:myDefaultContact'
            element.attributes.collect{|x|x[0]}.sort.should == ["sdata:descriptor", "sdata:key", "sdata:url", "sdata:uuid"]
            element.attributes['sdata:descriptor'].value.should == "Contact #123: Contact Name"
          when 'crmErp:myContacts'
            found_with_uuid, found_without_uuid = false
            element.children.size.should == 2
            element.children.each do |child_element|
              if child_element.attributes['sdata:uuid']
                found_with_uuid = true
                child_element.attributes.collect{|x|x[0]}.sort.should == ["sdata:descriptor", "sdata:key", "sdata:url", "sdata:uuid"]
                child_element.attributes['sdata:uuid'].value.should == "C-123-456"
              else
                found_without_uuid = true
                child_element.attributes.collect{|x|x[0]}.sort.should == ["sdata:descriptor", "sdata:key", "sdata:url"]
              end
              child_element.attributes['sdata:descriptor'].value.should =~ /Contact ##{child_element.attributes['sdata:key'].value}.*/
            end
            found_with_uuid.should == true
            found_without_uuid.should == true
          end
        end
      end

      it "properly escapes xml content in user data" do
        Customer.class_eval { acts_as_sdata(:content => :sdata_content) }
        Contact.class_eval { acts_as_sdata(:content => :sdata_content) }
        @customer.name = "</crmErp:name><div>asdf</div>"
        @customer.number = "<div>123456</div>"
        @customer.to_atom.payload.to_s.include?("</crmErp:name><div>asdf</div>").should == false
        @customer.to_atom.payload.to_s.include?("<div>123456</div>").should == false
        @customer.to_atom.payload.to_s.include?("&lt;/crmErp:name&gt;&lt;div&gt;asdf&lt;/div&gt;").should == true
        @customer.to_atom.payload.to_s.include?("&lt;div&gt;123456&lt;/div&gt;").should == true
      end  
      
      #?include param (other than $children or $descriptors) is not properly implemented yet, and is not identified by Brian as first-priority request,
      #so not writing tests for it yet.
    end
  end
end