require File.join(File.dirname(__FILE__), 'spec_helper')

describe SData::Resource do
  describe "#registered_resources" do
    context "when I inherit couple of classes" do
      before :each do
        class TradingAccount < SData::Resource; end
        class SalesInvoice < SData::Resource; end
      end

      it "should give access to children by symbol" do
        SData::Resource.registered_resources[:trading_account].should == TradingAccount
        SData::Resource.registered_resources[:sales_invoice].should == SalesInvoice
      end

      context "when child classes are in namespaces" do
        before :each do
          module SData
            module Contracts
              module CrmErp
                class PostalAddress < SData::Resource; end
              end
            end
          end
        end

        # ??? perhaps namespace should be taken into account and be extracted from the URL (billingboss/crmErp/-/...)
        it "should give access to these children by keys without namespace" do
          SData::Resource.registered_resources[:postal_address].should == SData::Contracts::CrmErp::PostalAddress
        end
      end
    end
  end

  describe "#has_sdata_options" do
    context "when two SData resources with different options" do
      before :each do
        class TradingAccount < SData::Resource;
          has_sdata_options :value => 'TradingAccount'
        end

        class SalesInvoice < SData::Resource
          has_sdata_options :value => 'SalesInvoice'
        end
      end

      it "should respond to #sdata_options" do
        TradingAccount.should respond_to(:sdata_options)
        SalesInvoice.should respond_to(:sdata_options)
      end

      it "should return correspondent value" do
        TradingAccount.sdata_options.should == { :value => 'TradingAccount' }
        SalesInvoice.sdata_options.should == { :value => 'SalesInvoice' }
      end
    end
  end
end