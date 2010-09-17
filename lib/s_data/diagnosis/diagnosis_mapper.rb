module SData
  class Diagnosis
    class DiagnosisMapper
      def self.map(exception, request_path='')
        error_payload = case exception.class.name.demodulize
        when 'NoMethodError'
          if request_path.match /^\/#{SData.store_path}\/[^\/]+\/[A-z]+\/.*/ 
            SData::ApplicationDiagnosis.new(:exception => exception, :http_status_code => '500')          
          elsif request_path.match /^\/#{SData.store_path}\/[^\/]+\/[A-z]+/ 
            SData::ResourceKindNotFound.new(:exception => exception, :http_status_code => '404')
          elsif request_path.match /^\/#{SData.store_path}\/[^\/]+$/
            SData::ApplicationDiagnosis.new(:exception => exception, :http_status_code => '501')
          elsif request_path.match /^\/#{SData.store_path}.+/
            SData::DatasetNotFound.new(:exception => exception, :http_status_code => '404')
          elsif request_path.match /^\/#{SData.store_path}$/
            SData::ApplicationDiagnosis.new(:exception => exception, :http_status_code => '501')
          elsif request_path.match /^\/sdata\/#{SData.config[:application]}.+/  
            SData::ContractNotFound.new(:exception => exception, :http_status_code => '404')
          elsif request_path.match /^\/sdata\/#{SData.config[:application]}$/  
            SData::ApplicationDiagnosis.new(:exception => exception, :http_status_code => '501')
          else
            SData::ApplicationNotFound.new(:exception => exception, :http_status_code => '404')
          end
        when 'AccessDeniedException'
          SData::ApplicationDiagnosis.new(:exception => exception, :http_status_code => '403')
        when 'ExpiredSubscriptionException'
          SData::ApplicationDiagnosis.new(:exception => exception, :http_status_code => '402')
        when 'UnauthenticatedException'
          SData::ApplicationDiagnosis.new(:exception => exception, :http_status_code => '401')
        when 'IncompatibleDataException'
          SData::BadWhereSyntax.new(:exception => exception, :http_status_code => '409')
        when 'NotFound'
          SData::ResourceKindNotFound.new(:exception => exception, :http_status_code => '404')
        else
          SData::ApplicationDiagnosis.new(:exception => exception, :http_status_code => '500')
        end
        error_payload
      end
    end
  end
end