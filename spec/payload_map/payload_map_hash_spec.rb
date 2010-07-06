require File.join(File.dirname(__FILE__), '..', 'spec_helper')

include SData::PayloadMap

describe PayloadMapHash do
  context "given a hash with payload map" do
    before :each do
      @hash = {
        :taxation_country       => { :baze_field => :country, :precedence => 3 },
        :short_name             => { :baze_field => :name, :precedence => 3 },

        :company_person_flag    => { :static_value => 'Company', :precedence => 50 },
        :customer_supplier_flag => { :static_value => 'Customers', :precedence => 50 },
        :nil_value              => { :static_value => nil, :precedence => 50 },
        :false_value              => { :static_value => false, :precedence => 50 },

        :billing_addresses      => { :proc => lambda { SData::PostalAddress.build_for([self.baze], :billing) }, 
                                     :precedence => 3},
                                     
        :thingy_with_deleted    => { :proc => lambda { SData::PostalAddress.build_for([self.baze], :billing) }, 
                                     :precedence => 3,
                                     :proc_with_deleted => lambda { puts "I am a lambda" } }
      }
    end

    context "when PayloadMapHash is initialized with such hash" do
      subject { PayloadMapHash.new(@hash) }

      it { should be_kind_of(Hash) }

      describe "#static_values" do
        it "should return only staic values as a key-value hash" do
          subject.static_values.should == {
            :company_person_flag => 'Company',
            :customer_supplier_flag => 'Customers',
            :false_value => false,
            :nil_value => nil
          }
        end
      end

      describe "#baze_fields" do
        it "should return only baze fields as a key-value hash" do
          subject.baze_fields.should == {
            :taxation_country => :country,
            :short_name => :name
          }
        end
      end

      describe "#attrs" do
        it "should return attrs as union of static_values & baze_fields" do
          subject.attrs.should == {
            :taxation_country       => { :baze_field => :country, :precedence => 3 },
            :short_name             => { :baze_field => :name, :precedence => 3 },

            :company_person_flag    => { :static_value => 'Company', :precedence => 50 },
            :customer_supplier_flag => { :static_value => 'Customers', :precedence => 50 },
            :false_value              => { :static_value => false, :precedence => 50 },
            :nil_value              => { :static_value => nil, :precedence => 50 }
          }
        end
      end

      describe "#procs" do
        it "should return only stored procs as a field_name-proc hash" do
          subject.procs.should == {
            :billing_addresses => @hash[:billing_addresses][:proc],
            :thingy_with_deleted => @hash[:thingy_with_deleted][:proc]
          }
        end
      end

      describe "#procs_with_deleted" do
        it "should return proc_with_deleted or otherwise proc as a field_name-proc hash" do
          subject.procs_with_deleted.should == {
            :billing_addresses => @hash[:billing_addresses][:proc],
            :thingy_with_deleted => @hash[:thingy_with_deleted][:proc_with_deleted]
          }
        end
      end
    end
  end
end