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

      describe "#static_values" do
        it "should return only staic values as a key-value hash" do
          subject.static_values.should == {
            :company_person_flag => 'Company',
            :customer_supplier_flag => 'Customers'
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

      describe "#map_field" do
        context "when given field exists in mapping as a baze field" do
          it "should return a baze field which it leads to" do
            subject.map_field(:taxation_country).should == :country
          end
        end

        context "when given field does not exist in mapping" do
          it "should return nil" do
            subject.map_field(:blablabla).should be_nil
          end
        end

        context "when given field exists in mapping as a static value" do
          it "should return nil" do
            subject.map_field(:company_person_flag).should be_nil
          end
        end
      end
    end
  end
end