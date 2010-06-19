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
      if self.exception && !self.message
        self.message = self.exception.message 
      end
      self.sdata_code ||= self.class.name.demodulize
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
      root_node['xmlns:sdata'] = "#{SData.config[:schemas]['sdata']}"
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
            node << (XML::Node.new("sdata:stackTrace") << value.backtrace.join("\n") ) if SData.config[:show_stack_trace]
          else
            node << (XML::Node.new("sdata:#{attribute.to_s.camelize(:lower)}") << value)
          end
        end
      end
      #nesting node in [] because of strange quirk in Atom::Content's mixin in AtomExtensions::ContentMixin,
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