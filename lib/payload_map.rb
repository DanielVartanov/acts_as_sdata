module SData  
  module PayloadMap
    def define_payload_map(map)
      cattr_accessor :payload_map
      cattr_accessor :payload

      self.payload_map = map
      self.payload = payload_fields_proxy
    end

  protected

    module PayloadFieldsProxy
      module ClassMethods
        def define_readers(readers)
          readers.each { |reader| attr_reader reader }
        end
      end

      module InstanceMethods
        def set_values(values)
          values.each_pair do |key, value|
            ivar_sym = "@#{key.to_s}".to_sym
            instance_variable_set ivar_sym, value
          end
        end
      end
    end

    def payload_fields_proxy
      proxy_class = Class.new
      proxy_class.extend PayloadFieldsProxy::ClassMethods
      proxy_class.__send__ :include, PayloadFieldsProxy::InstanceMethods
      proxy_class.define_readers(self.payload_map.keys)

      returning proxy_class.new do |proxy|
        field_values = self.payload_map.merge(self.payload_map) { |key, value| value[:static_value] }
        proxy.set_values(field_values)
      end
    end
  end
end

VirtualBase.extend SData::PayloadMap