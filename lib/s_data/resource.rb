module SData
  class Resource
    cattr_accessor :registered_resources

    def self.inherited(child)
      class << child
        include ClassMethods
      end

      child.register_resource
      child.define_own_sdata_options

      child.__send__ :include, SData::Traits::VirtualBase
    end

    def self.has_sdata_options(options)
      self.sdata_options = options
    end

    module ClassMethods
      def register_resource
        key = self.name.demodulize.underscore.to_sym
        (self.registered_resources ||= {})[key] = self
      end

      def define_own_sdata_options
        class << self
          attr_accessor :sdata_options
        end
        self.sdata_options = {}
      end
    end
  end
end
