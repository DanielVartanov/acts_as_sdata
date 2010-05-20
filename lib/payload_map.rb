module SData  
  module PayloadMap

    def define_payload_map(map)
      cattr_accessor :payload_map
      cattr_accessor :payload

      self.payload_map = PayloadMapHash.new(map)
      define_method(:payload) { @payload ||= payload_fields_proxy }
    end

  protected

    module PayloadFieldsProxy
      module ClassMethods
        def define_readers(readers)
          readers.each { |reader| attr_reader reader }
        end

        def define_baze_fields_references(baze_fields)
          baze_fields.each_pair do |key, value|
            define_method(key) { self.payload_map_owner.baze.__send__ value }
          end
        end
      end

      module InstanceMethods
        def set_static_values(static_values)
          static_values.each_pair do |key, value|
            ivar_sym = "@#{key.to_s}".to_sym
            instance_variable_set ivar_sym, value
          end
        end
      end
    end

    def payload_fields_proxy
      proxy_class = Struct.new(:payload_map_owner)
      proxy_class.extend PayloadFieldsProxy::ClassMethods
      proxy_class.__send__ :include, PayloadFieldsProxy::InstanceMethods

      proxy_class.define_readers(self.payload_map.static_values.keys)
      proxy_class.define_baze_fields_references(self.payload_map.baze_fields)

      returning proxy_class.new do |proxy|
        proxy.payload_map_owner = self
        proxy.set_static_values(self.payload_map.static_values)
      end
    end
  end
end

VirtualBase.extend SData::PayloadMap