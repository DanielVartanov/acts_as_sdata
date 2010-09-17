module SData
  module Traits
    VirtualBase = Trait.new do
      extend Forwardable
      include SData::Sync::ResourceMixin

      cattr_accessor :baze_class

      cattr_accessor :owner_key
      self.owner_key = 'created_by_id'

      attr_accessor :baze
      def_delegators :baze, :id, :created_at, :updated_at, :save, :save!, :update_attributes, :update_attributes!, :created_by, :reload

      def initialize(the_baze=nil, the_type=nil)
        self.baze = the_baze
        self.baze ||= self
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
        @baze_class_name ||= self.class.baze_class_name
        @baze_class_name ||= self.baze_class_name_from_baze_instance
      end

      # TODO: I don't think we should demodulize here. We may be screwing up consumer's use of namespaces. But taking it out will require a lot of test fixing
      def baze_class_name_from_baze_instance
        klass = baze.class
        while(!klass.descends_from_active_record?) do; klass = klass.superclass; end
        klass.name.demodulize
       end

      def reference
        # GCRM requires reference to be present and unique to each GCRM model. Decided to use baze id, but
        # alone it is insufficient because some GCRM models (e.g. Address) can have the same baze id for different
        # bazes (e.g. customer vs user). So using the form below.
        # Adding GCRM model name is fine but unneeded. GCRM name _only_, without BB model name, is insufficient.
        "#{self.baze_class_name}_#{self.baze.id}"
      end

      def sd_class
        self.class.name
      end

      # Override to provide automatic creation of sd_uuids. Currently, this automatic creation will only happen
      # when records are requested by id or as a collection.
      def sdata_uuid_for_record
        nil
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

      # database foreign_key for owner. Redefine in subclasses if necessary
      def owner_id
        owner.nil? ? nil : owner.id
      end

      # TODO -- should return all bb models that are used to composite the virtual model (or at least the subset whose modifications must be tracked)
      def self.baze_classes
        @baze_classes ||= [self.baze_class]
      end

      # TODO: I don't think we should demodulize here. We may be screwing up consumer's use of namespaces. But taking it out will require a lot of test fixing
      def self.baze_class_names
        @baze_class_names ||= [self.baze_class.name.demodulize]
      end

      # TODO: I don't think we should demodulize here. We may be screwing up consumer's use of namespaces. But taking it out will require a lot of test fixing
      def self.baze_class_name
        @baze_class_name = (baze_class.nil? ? nil : baze_class.name.demodulize)
      end

      def self.sdata_name
        name.demodulize
      end

      def self.find(*params)
        self.new(self.baze_class.find(*params))
      end

      def self.find_with_deleted(*params)
        self.new(self.baze_class.find_with_deleted(*params))
      end

      def self.first(*params)
        self.new(self.baze_class.first(*params))
      end

      def self.all(*params)
        self.collection(self.baze_class.all(*params))
      end

      def self.all_with_deleted(*params)
        self.collection(self.baze_class.find_with_deleted(:all, *params))
      end

      def self.collection(arr)
        arr.map do |obj|
          case obj
          when VirtualBase, DeletedObjectProxy
            obj
          when ActiveRecord::Base
            self.virtual_base_for_object(obj)
          else
            obj
          end
        end
      end

      extend SData::ActiveRecordExtensions::Mixin
      extend SData::ActiveRecordExtensions::SdataUuidableMixin
    end
  end
end
