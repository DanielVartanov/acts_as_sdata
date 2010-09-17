module SData
  class Payload
    
    attr_accessor :builder, :root_node_name, :included, :selected, :maximum_precedence, :sync, :contract
    attr_accessor :xml_node, :entity, :expand, :dataset
    
    def initialize(params)
      self.builder = Builder::XmlMarkup.new
      self.included = params[:included]
      self.selected = params[:selected]
      self.maximum_precedence = params[:maximum_precedence]
      self.sync = params[:sync]
      self.contract = params[:contract]
      self.expand = params[:expand]
      self.entity = params[:entity]
      self.dataset = params[:dataset]
    end

    def ==(other)
      return false unless other.is_a?(SData::Payload)
      [:root_node_name, :included, :selected, :maximum_precedence, :sync, :contract, :entity, :expand].all?{|attr| self.send(attr) == other.send(attr)}
    end

    def self.is_sync?
      false
    end

    def is_sync?
      !sync.nil? ? sync : Payload.is_sync?
    end
    
    def self.parse(xml)
      returning new do |payload|
        payload.xml_node = xml
      end
    end

    def to_xml(*params)
      node = XML::Node.new("sdata:payload")
      generate! if @xml_node.nil?
      node << @xml_node
      return node
    end
    
    def generate!
      @xml_node = generate(entity.sdata_node_name, entity, expand, 1, nil)
    end
    
    def generate(node_name, node_value, expand, element_precedence, resource_collection)
      self.root_node_name ||= node_name
      return "" if element_precedence > maximum_precedence
      return "" if excluded_in_select?(node_name)
      if node_value.respond_to?(:sdata_options)
        construct_from_sdata_model(node_name, node_value, expand, element_precedence, resource_collection)
      elsif node_value.is_a?(Array)
        construct_from_array(node_name, node_value, expand, element_precedence, resource_collection)
      elsif node_value.is_a?(Hash)
        construct_from_hash(node_name, node_value, expand, element_precedence, resource_collection)
      else
        construct_from_string(node_name, node_value, expand, element_precedence, resource_collection)
      end
    end
  
    def construct_from_sdata_model(node_name, node_value, expand, element_precedence, resource_collection)
      node = XML::Node.new(qualified(node_name))
      attributes = node_value.resource_header_attributes(dataset, included)
      attributes.each_pair do |key,value|
        node[key] = value.to_s
      end
      if (node_name == self.root_node_name) || (expand != :none) || included.include?(node_name)
        expand = :none if (expand == :immediate_children) 
        node_value.payload_map.each_pair do |child_node_name, child_node_data|
          if child_node_data[:type] == :association
            child_expand = :none
          else
            child_expand = (is_sync? ? :all_children : expand)
          end
          collection = ({:parent => node_value, :url => child_node_data[:sdata_node_name], :type => node_value.payload_map[child_node_name][:type]})
          attribute_method_name = sdata_attribute_method(child_node_data)
          node << generate(child_node_data[:sdata_node_name], node_value.send(attribute_method_name), child_expand, child_node_data[:precedence], collection)
        end
      end
      node
    end
    
    # this doesn't belong here. sdata attribute definitions should be real objects not hashes, so they can figure this stuff out themselves
    def sdata_attribute_method(attribute_definition)
      is_sync? ? attribute_definition[:method_name_with_deleted] : attribute_definition[:method_name]
    end
    
    def construct_from_array(node_name, node_value, expand, element_precedence, resource_collection)
      if resource_collection && resource_collection[:type]
        construct_from_sdata_array(node_name, node_value, expand, element_precedence, resource_collection)
      else
        construct_from_non_sdata_array(node_name, node_value, expand, element_precedence, resource_collection)
      end
    end
  
    def construct_from_sdata_array(node_name, node_value, expand, element_precedence, resource_collection)
      expand = :none if (expand == :immediate_children)
      node = XML::Node.new(qualified(node_name))
      scoped_children_collection = sdata_collection_url(resource_collection[:parent], resource_collection[:url])
      node['sdata:url'] = scoped_children_collection
      node_value.each do |item|
        node << generate(item.sdata_node_name, item, expand, element_precedence, nil)
      end
      node
    end
      
    def construct_from_non_sdata_array(node_name, node_value, expand, element_precedence, resource_collection)
      expand = :none if (expand == :immediate_children) 
      node = XML::Node.new(qualified(node_name))
      node_value.each do |item|
        node << generate(node_name.singularize, item, expand, element_precedence, (item.is_a?(Hash) ? item[:resource_collection] : nil))
      end
      node      
    end
      
    def construct_from_hash(node_name, node_value, expand, element_precedence, resource_collection)
      expand = :none if (expand == :immediate_children) 
      node = XML::Node.new(qualified(node_name))
      node_value.each_pair do |child_node_name, child_node_data|
        node << generate(formatted(child_node_name), child_node_data, expand, element_precedence, (child_node_data.is_a?(Hash) ? child_node_data[:resource_collection] : nil))
      end
      node
    end

    def construct_from_string(node_name, node_value, expand, element_precedence, resource_collection)
      node = XML::Node.new(qualified(node_name))
      if !node_value.to_s.blank?
        node << node_value
      else
        node['xsi:nil'] = 'true'
      end
      node
    end

    def qualified(node_name)
      "#{contract}:#{node_name}"
    end

    def formatted(node_name)
      node_name.to_s.camelize(:lower)
    end

    def sdata_collection_url(parent, child)
      #FIXME: adjust for bookkeeper support
      SData.endpoint + "/#{dataset}/" + parent.sdata_node_name + "('#{parent.id}')/" + child
    end

    def excluded_in_select?(node_name)
      return false if selected.empty?
      return false if node_name == self.root_node_name
      return !selected.include?(node_name.to_s.camelize(:lower))
    end

  end
end