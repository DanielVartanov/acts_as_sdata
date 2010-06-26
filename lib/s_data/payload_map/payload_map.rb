

module SData
  module PayloadMap
    def define_payload_map(map)
      include InstanceMethods
      cattr_accessor :payload_map
      self.payload_map = PayloadMapHash.new(map)
      self.payload_map.each do |name, opts|
        has_sdata_attr(name, opts)
      end
    end

    def has_sdata_attr(*args)
      options = args.last.is_a?(Hash) ? args.pop : {:static_value => nil, :precedence => 50}
      args.each do | name |
        options[:method_name] ||= name
        options[:method_name_with_deleted] = options[:method_name]
        
        method_name = options[:method_name]
        payload_map[name] ||= options
        
        case field_type(options)
        when :static_value
          define_static_value_reader method_name, options[:static_value]

        when :baze_field
          define_baze_field_reference method_name, options[:baze_field]

        when :method

        when :proc
          define_proc_caller method_name, options[:proc]

          if options.has_key?(:proc_with_deleted)
            method_name_with_deleted = options[:method_name_with_deleted] = "#{method_name.to_s}_with_deleted"
            define_proc_with_deleted_caller method_name_with_deleted, options[:proc_with_deleted]
          end

        else
          raise SData::Exceptions::VirtualBase::InvalidSDataAttribute.new(
              "#{args.join(", ")}: must supply a static_value, baze_field, method or proc")
        end
      end
    end

    def has_sdata_association(*args)
      options = args.last.is_a?(Hash) ? args.pop : {:precedence => 50, :type => :association}
      options[:type] ||= :association
      raise SData::Exceptions::VirtualBase::InvalidSDataAssociation.new(
          "#{args.join(", ")}: must supply a proc or method") unless [:proc, :method].any?{|k|options.has_key?(k)}
      raise SData::Exceptions::VirtualBase::InvalidSDataAssociation.new(
          "#{args.join(", ")}: invalid association type '#{options[:type]}") unless [:association, :child].include?(options[:type])
      args.push options
      has_sdata_attr(*args)
    end
    
    module InstanceMethods
      def payload
        self
      end
      
      
      # Walks the payload, loading each association, descending into children, and yielding the tuple
      # [payload_map_definition, node_object(s)] for each node. Can use without a block
      # to fire all faults -- sync uses this when caching changed objects.
      def associations_with_deleted(expand=:all_children)
        return if expand == :none
        payload_map.each_pair do |child_node_name, child_node_data|
          if child_node_data[:type] == :association
            expand = :none
          elsif child_node_data[:type] == :child
            expand = :all_children
          else
            next
          end
          child = __send__(child_node_data[:method_name_with_deleted])
          yield child_node_data.merge(:name => child_node_name), child if block_given?
          case child
          when Array
            child.each{ |grandchild| grandchild.associations_with_deleted(expand) if child.is_a?(SData::VirtualBase)}
          when SData::VirtualBase
            associations_with_deleted(expand)
          end
        end
      end      
    end

  protected

    def field_type(options)
      [:static_value, :baze_field, :method, :proc].each do |type|
        if options.has_key?(type)
          return type
        end
      end
      nil
    end

    def define_static_value_reader(method_name, value)
      class_eval do
        define_method method_name do
          value
        end
      end
    end

    def define_baze_field_reference(method_name, baze_field)
      class_eval do
        define_method method_name do
          self.baze.__send__ baze_field
        end
      end
    end

    def define_proc_caller(method_name, block)
      class_eval do
        define_method method_name, block
      end
    end

    def define_proc_with_deleted_caller(method_name, block)
      cache_var = "@#{method_name.to_s}_cached"
      class_eval do
        define_method(method_name) do
          unless instance_variable_get(cache_var)
            instance_variable_set(cache_var, instance_eval(&block))
          end
          instance_variable_get(cache_var)
        end
      end
    end
  end
end

SData::VirtualBase.extend SData::PayloadMap