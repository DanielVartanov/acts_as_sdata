TradingAccount = Struct.new :id, :uuid

class Payload < Struct.new(:trading_account)
  def to_xml
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.payload(
        'xmlns:sdata' => "http://schemas.sage.com/sdata/2008/1") {
          xml['sdata'].tradingAccount :uuid => trading_account.uuid,
                                      :url => "http://www.billingboss.com/myApp/myContract/-/tradingAccounts!#{trading_account.id}"
      }
    end

    builder.to_xml
  end
end