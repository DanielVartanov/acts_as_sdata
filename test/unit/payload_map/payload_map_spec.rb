require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe SData::PayloadMap do
  context "given a VirtualBase class extended by SData::PayloadMap" do
    before :each do
      VirtualBase.extend SData::PayloadMap
    end

    it "should respond to #payload_map class method" do
      VirtualBase.should respond_to(:define_payload_map)
    end

    describe "#define_payload_map" do
      context "when mapping leads to static value" do
        before :each do
          VirtualBase.define_payload_map :tax_reference => { :static_value => 'Some static tax reference' }
        end

        subject { VirtualBase.new(Object) }

        it { should respond_to(:payload) }

        context "when correspondent field method is called" do
          it "should return given static value" do
            subject.payload.tax_reference.should == 'Some static tax reference'
          end
        end

        describe "#payload_map" do
          subject { VirtualBase.new(Object).payload_map }

          it { should == { :tax_reference => { :static_value => 'Some static tax reference' } } }
        end
      end

      context "when mapping leads to a baze field" do
        before :each do
          @baze = Struct.new(:country).new('Kyrgyzstan')

          VirtualBase.baze_class = Customer
          VirtualBase.define_payload_map :taxation_country => { :baze_field => :country }
        end

        subject { VirtualBase.new(@baze) }

        it "should apply to baze class" do
          subject.payload.taxation_country.should == @baze.country
        end

        it "should not cache value, but fetch it each time" do
          @baze.country = 'Canada'
          subject.payload.taxation_country.should == 'Canada'
        end
      end
    end
  end
end