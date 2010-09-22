require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe SData::PayloadMap do
  context "given sdata model class extended by SData::PayloadMap" do
    before :all do
      class TradingAccount < SData::Resource
#        extend SData::PayloadMap
#
        define_payload_map :foo => { :static_value => :bar }

        # temporary
        def method_missing(meth, *args, &block)
          if @payload
            @payload.send(meth, *args, &block)
          else
            super
          end      
        end
      end
    end

    it "should respond to #payload_map class method" do
      TradingAccount.should respond_to(:define_payload_map)
    end

    it "should respond to #has_sdata_attr class method" do
      TradingAccount.should respond_to(:has_sdata_attr)
      #QUESTION: do we really need this method to be public?
    end

    describe "#define_payload_map" do
      context "when mapping leads to static value" do
        before :each do
          TradingAccount.define_payload_map :tax_reference => { :static_value => 'Some static tax reference' }
        end

        subject { TradingAccount.new(Object) }

        it { should respond_to(:payload) }

        context "when correspondent field method is called" do
          it "should return given static value" do
            subject.tax_reference.should == 'Some static tax reference'
          end
        end

        describe "#payload_map" do
          it "should store it correctly" do
            subject.payload_map[:tax_reference].should == { :static_value => 'Some static tax reference', :method_name => :tax_reference, :method_name_with_deleted=>:tax_reference, :sdata_node_name=>"taxReference"}
          end
        end
      end

      context "when mapping leads to a baze field" do
        before :each do
          @baze = Struct.new(:country).new('Kyrgyzstan')

          TradingAccount.baze_class = Customer
          TradingAccount.define_payload_map :taxation_country => { :baze_field => :country }
        end

        subject { TradingAccount.new(@baze) }

        it "should apply to baze class" do
          subject.taxation_country.should == @baze.country
        end

        it "should not cache value, but fetch it each time" do
          @baze.country = 'Canada'
          subject.taxation_country.should == 'Canada'
        end
      end

      context "when mapping leads to a proc" do
        before :each do
          @mock = mock("thing", :dynamic => 1, :dynamic_deleted => 3)
          mock = @mock
          TradingAccount.define_payload_map :dynamic_field => { :proc => lambda { mock.dynamic }, :proc_with_deleted  => lambda { mock.dynamic_deleted }}
        end

        subject { TradingAccount.new(Object) }

        it "should call given lambda each time" do
          @mock.should_receive(:dynamic).twice
          2.times { subject.dynamic_field }
        end

        it "should return lambda's return value" do
          expected_return_value = 123456
          @mock.stub! :dynamic => expected_return_value
          subject.dynamic_field.should == expected_return_value
        end

        it "should set the method_name in the options to the attribute name" do
          subject.payload_map[:dynamic_field][:method_name].should == :dynamic_field
        end
        
        it "should create a xxx_with_deleted method" do
          expected_return_value = 498
          @mock.stub! :dynamic_deleted => expected_return_value
          subject.dynamic_field_with_deleted.should == expected_return_value
        end
        
        context "consider lambda calls local object methods" do
          before :each do
            TradingAccount.__send__ :attr_accessor, :local_field
            TradingAccount.define_payload_map :access_to_local_field => { :proc => lambda { self.local_field } }
          end

          subject { TradingAccount.new(Object) }

          it "should run lambda in context of SData model object" do
            subject.local_field = 654321
            subject.access_to_local_field.should == 654321
          end
        end
      end
    end

    describe "#has_sdata_attr" do
      before :each do
        @mock_baze = mock("thing", :dude => "sweet")
      end

      subject { TradingAccount.new(@mock_baze) }

      it "should add a static value attr" do
        TradingAccount.has_sdata_attr :some_static_value, { :static_value => 42 }
        subject.some_static_value.should == 42
      end

      it "should add a static value attr whose value is nil" do
        TradingAccount.has_sdata_attr :some_nil, { :static_value => nil }
        subject.some_nil.should be_nil
      end

      it "should add a baze_field attr" do
        TradingAccount.has_sdata_attr :some_baze_value, { :baze_field => :dude }
        subject.some_baze_value.should == "sweet"
      end
      
    end
  end
end
