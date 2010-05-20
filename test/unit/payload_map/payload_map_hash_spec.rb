require File.join(File.dirname(__FILE__), '..', 'spec_helper')

include SData::PayloadMap

describe PayloadMapHash do
  context "given a hash with payload map" do
    before :each do
      @hash = {
        :taxation_country => { :baze_field => :country, :precedence => 3 },
        :short_name => { :baze_field => :name, :precedence => 3 },

        :company_person_flag => { :static_value => 'Company', :precedence => 50 },
        :customer_supplier_flag => { :static_value => 'Customers', :precedence => 50 }
      }
    end

    context "when PayloadMapHash is initialized with such hash" do
      subject { PayloadMapHash.new(@hash) }

      it { should be_kind_of(Hash) }

      context "#static_values" do
        it "should return only staic values as a key-value hash" do
          subject.static_values.should == {
            :company_person_flag => 'Company',
            :customer_supplier_flag => 'Customers'
          }
        end
      end

      context "#baze_fields" do
        it "should return only baze fields as a key-value hash" do
          subject.baze_fields.should == {
            :taxation_country => :country,
            :short_name => :name
          }
        end
      end
    end
  end
end