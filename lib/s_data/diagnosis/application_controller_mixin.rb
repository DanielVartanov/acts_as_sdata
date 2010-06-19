module SData
  module ApplicationControllerMixin
    def sdata_rescue_support
      self.__send__ :include, SDataRescue
    end
    
    module SDataRescue
      def sdata_global_rescue(exception, request_path)
        RAILS_DEFAULT_LOGGER.debug("sdata_global_rescue. exception: #{exception.inspect} request_path: #{request_path.inspect}")
        error_payload = SData::Diagnosis::DiagnosisMapper.map(exception, request_path)
        render :xml => error_payload.to_xml(:root), :status => (error_payload.send('http_status_code') || '500')
      end
    end
  end
end
ActionController::Base.extend SData::ApplicationControllerMixin