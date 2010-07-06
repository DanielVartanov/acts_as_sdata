module SData
  class SdUuid
    @@test_uuids = []
    [
      {:sd_class => 'Customer', :bb_model_type => 'Customer', :bb_model_id => 12345, :uuid => 'CUST-10000'},
      {:sd_class => 'Address', :bb_model_type => 'Customer', :bb_model_id => 12345, :uuid => 'ADDR-10001'},
      {:sd_class => 'Contact', :bb_model_type => 'Contact', :bb_model_id => 23456, :uuid => 'CONT-10002'},
      {:sd_class => 'Contact', :bb_model_type => 'Contact', :bb_model_id => 123, :uuid => 'C-123-456'},
      {:sd_class => 'Customer', :bb_model_type => 'Customer', :bb_model_id => 23456, :uuid => 'CUST-10003'},
    ].each do |params|
      @@test_uuids << OpenStruct.new(params)
    end

    
    def self.first(params)
      match = nil
      @@test_uuids.each do |record|
        if (record.sd_class == params[:conditions][:sd_class] and 
           record.bb_model_type == params[:conditions][:bb_model_type] and 
           record.bb_model_id == params[:conditions][:bb_model_id]) 
           
          match = record 
        end
      end
      return match
    end
  end
end