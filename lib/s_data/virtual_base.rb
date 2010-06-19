module SData
  class VirtualBase
    extend Forwardable
    include SData::Sync::SdataSyncingMixin
    
    class << self
      attr_accessor :baze_class
    end
    
    class_inheritable_accessor :owner_key    
    self.owner_key = 'created_by_id'
    
    attr_accessor :baze
    def_delegators :baze, :id, :created_at, :updated_at, :save, :save!, :update_attributes, :update_attributes!, :created_by, :reload
  
    def initialize(the_baze, the_type=nil)
      @uuid_class = SData::SdUuid      
      self.baze = the_baze
      if self.respond_to?('sdata_type') && the_type
        self.sdata_type = the_type
      end
      super()
    end

    # temporary
    def method_missing(meth, *args, &block)
      if @payload
        @payload.send(meth, *args, &block)
      else
        super
      end      
    end

    def baze_class_name
      self.class.baze_class_name
    end
    
    def reference
      # GCRM requires reference to be present and unique to each GCRM model. Decided to use baze id, but
      # alone it is insufficient because some GCRM models (e.g. Address) can have the same baze id for different
      # bazes (e.g. customer vs user). So using the form below.
      # Adding GCRM model name is fine but unneeded. GCRM name _only_, without BB model name, is insufficient.
      "#{self.baze.class.name.demodulize}_#{self.baze.id}"
    end
    
    def self.build_for(data, the_type=nil)
      if data.is_a? Array
        data.map {|item| virtual_base_for_object(item, the_type) }.compact
      else
       virtual_base_for_object(data, the_type)
      end
    end
    
    def self.virtual_base_for_object(obj, the_type=nil)
      if obj
        vb = self.new(obj, the_type)
        vb = DeletedObjectProxy.from_virtual_base(vb) if obj.class.paranoid? && obj.deleted?
        vb
      else
        nil
      end
    end
    
    def owner
      raise "Security problem: owner not defined in subclass!"
    end

    # TODO -- should return all bb models that are used to composite the virtual model (or at least the subset whose modifications must be tracked)

    def self.baze_classes
      [self.baze_class]
    end
    
    def self.baze_class_name
      baze_class.nil? ? nil : baze_class.name.demodulize
    end
    
    def self.sdata_name
      name.demodulize
    end

    def self.find(*params)
      self.new(self.baze_class.find(*params))
    end

    def self.first(*params)
      self.new(self.baze_class.first(*params))
    end
  
    def self.all(*params)
      self.collection(self.baze_class.all(*params))
    end
    
    def self.collection(arr)
      arr.map do |obj| 
        case obj
        when VirtualBase, DeletedObjectProxy
          obj
        when ActiveRecord::Base
          self.new(obj)
        else
          obj
        end
      end
    end
    
  end
  VirtualBase.extend SData::ActiveRecordExtensions::Mixin
  VirtualBase.extend SData::ActiveRecordExtensions::SdataUuidableMixin  
end