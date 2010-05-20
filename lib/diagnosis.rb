module SData

  class Diagnosis

    @@sdata_attributes = [:severity, :sdata_code, :application_code, :message, :stack_trace, :payload_path, :exception, :http_status_code]
    @@sdata_attributes.each {|attr| attr_accessor attr}

    def initialize(params={})
      raise "SData::Diagnosis is an abstract class; instantiate a subclass instead" if self.class == SData::Diagnosis
      params.each_pair do |key,value|
        if @@sdata_attributes.include?(key)
          self.send("#{key}=", value)
        end
      end
      self.message ||= self.exception.message if self.exception && !['production', 'staging'].include?(ENV['RAILS_ENV']) 
      self.sdata_code ||= self.class.to_s.demodulize
      self.severity ||= "error"
    end

    def to_xml(mode=:root)
      case mode
      when :root
        return Diagnosis.construct_header_for(self.diagnosis_payload)
      when :feed
        return self.diagnosis_payload[0]
      when :entry
        return self.diagnosis_payload
      end
    end
    
    #Can be called from outside to build a single header for multiple diagnoses, each of which has been
    #constructed with (header=false) option. Useful when generating multiple diagnoses inside a single Feed.
    #Currently won't work inside a signle Entry due to parsing problems in rAtom.
    #Solving this problem is complex, so won't try to implement unless we confirm it's required. -Eugene
    def self.construct_header_for(diagnosis_payloads)
      document = XML::Document.new
      root_node = XML::Node.new("sdata:diagnoses")
      #TODO FIXME: SData spec says root node must be just 'xmlns=' and not 'xmlns:sdata', but this fails W3
      #XML validation. Confirm which way is correct -- if former, change below line to root_node['xmlns']...
      root_node['xmlns:sdata'] = "#{Namespace.sdata_schemas['sdata']}"
      diagnosis_payloads.each do |diagnosis_payload|
        root_node << diagnosis_payload
      end
      document.root = root_node
      document
    end

    protected
    
    def diagnosis_payload
      node = XML::Node.new("sdata:diagnosis")
      @@sdata_attributes.each do |attribute|
        value = self.send(attribute) unless [:http_status_code].include?(attribute)
        if value
          if value.is_a?(Exception)
            node << (XML::Node.new("sdata:stackTrace") << value.backtrace.join("\n") ) if !['production', 'staging'].include?(ENV['RAILS_ENV'])
          else
            node << (XML::Node.new("sdata:#{attribute.to_s.camelize(:lower)}") << value)
          end
        end
      end
      #nesting node in [] because of strange quirk in Atom::Content's mixin in atom_content_mixin,
      #in which .self becomes the return value of this method, but doesn't escape properly in the Atom Entry
      #making .self be [node] and then calling self[0] works fine.
      [node]
    end
    
  end

  #potential TODO: write a static class-generating method which diagnoses exception and decides what kind of
  #error payload class to return (caller will then instantiate it)

  #customize as needed
  class BadUrlSyntax < Diagnosis
    def initialize(params={})
      self.http_status_code = '400'
      super(params)
    end
  end
  class BadQueryParameter < Diagnosis
    def initialize(params={})
      self.http_status_code = '400'
      super(params)
    end    
  end
  class ApplicationNotFound < Diagnosis
    def initialize(params={})
      self.http_status_code = '404'
      super(params)
    end    
  end
  class ApplicationUnavailable < Diagnosis
    def initialize(params={})
      self.http_status_code = '503'
      super(params)
    end    
  end
  class DatasetNotFound < Diagnosis
    def initialize(params={})
      self.http_status_code = '404'
      super(params)
    end    
  end
  class ContractNotFound < Diagnosis
    def initialize(params={})
      self.http_status_code = '404'
      super(params)
    end    
  end
  class ResourceKindNotFound < Diagnosis
    def initialize(params={})
      self.http_status_code = '404'
      super(params)
    end    
  end
  class BadWhereSyntax < Diagnosis
    def initialize(params={})
      self.http_status_code = '400'
      super(params)
    end    
  end
  class ApplicationDiagnosis < Diagnosis
    def initialize(params={})
      self.http_status_code = '500'
      super(params)
    end    
  end
  
end

#TODO: write unit/cucumber tests for all those cases!
module SData
  module ApplicationControllerMixin
    def sdata_rescue_support
      self.__send__ :include, SDataRescue
    end
    
    module SDataRescue
      #TODO: rescue_action_in_public won't work for some reason here. When merging with real Billing Boss app,
      #investigate. Need to preserve stack traces for dev env for non-simply requests.
      def sdata_global_rescue(exception, request_path)
        error_payload = case exception.class.to_s.demodulize
        when 'NoMethodError'
          if request_path.match /^\/sdata\/#{$SDATA_HIERARCHY[0]}\/#{$SDATA_HIERARCHY[1]}\/#{$SDATA_HIERARCHY[2]}\/[A-z]+\/.*/ 
            SData::ApplicationDiagnosis.new(:exception => exception, :http_status_code => '500')          
          elsif request_path.match /^\/sdata\/#{$SDATA_HIERARCHY[0]}\/#{$SDATA_HIERARCHY[1]}\/#{$SDATA_HIERARCHY[2]}\/[A-z]+/ 
            SData::ResourceKindNotFound.new(:exception => exception, :http_status_code => '404')
          elsif request_path.match /^\/sdata\/#{$SDATA_HIERARCHY[0]}\/#{$SDATA_HIERARCHY[1]}\/#{$SDATA_HIERARCHY[2]}$/
            SData::ApplicationDiagnosis.new(:exception => exception, :http_status_code => '501')
          elsif request_path.match /^\/sdata\/#{$SDATA_HIERARCHY[0]}\/#{$SDATA_HIERARCHY[1]}.+/
            SData::ContractNotFound.new(:exception => exception, :http_status_code => '404')
          elsif request_path.match /^\/sdata\/#{$SDATA_HIERARCHY[0]}\/#{$SDATA_HIERARCHY[1]}$/
            SData::ApplicationDiagnosis.new(:exception => exception, :http_status_code => '501')
          elsif request_path.match /^\/sdata\/#{$SDATA_HIERARCHY[0]}.+/  
            SData::DatasetNotFound.new(:exception => exception, :http_status_code => '404')
          elsif request_path.match /^\/sdata\/#{$SDATA_HIERARCHY[0]}$/  
            SData::ApplicationDiagnosis.new(:exception => exception, :http_status_code => '501')
          else
            SData::ApplicationNotFound.new(:exception => exception, :http_status_code => '404')
          end
        when 'AccessDeniedException'
	        SData::ApplicationDiagnosis.new(:exception => exception, :http_status_code => '403')
        else
          SData::ApplicationDiagnosis.new(:exception => exception, :http_status_code => '500')
        end
        render :xml => error_payload.to_xml(:root), :status => (error_payload.send('http_status_code') || '500')
      end
    end
  end
end
ActionController::Base.extend SData::ApplicationControllerMixin
