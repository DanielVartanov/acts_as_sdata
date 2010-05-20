class Payload

  # FIXME: temporary
  # is_sync? should be passed as param to generate, and should be true if feed is a synch feed.
  # In this case, ?include will show only links and not embedded data for associations,
  # while ?include=$children will be implied
  def self.is_sync?
    false
  end
  
  def self.generate(*params)
    node_name, node_value, expand, included, selected, element_precedence, maximum_precedence, resource_collection = *params
    expand = :all_children if is_sync?
    return "" if element_precedence > maximum_precedence
    return "" if self.excluded_in_select?(node_name, selected)
    builder = Builder::XmlMarkup.new
    if node_value.respond_to?('payload_map')
      self.construct_from_sdata_model(*params)
    elsif node_value.is_a?(Array)
      self.construct_from_array(*params)
    elsif node_value.is_a?(Hash)
      self.construct_from_hash(*params)
    else
      self.construct_from_string(*params)
    end
  end
  
  def self.construct_from_sdata_model(node_name, node_value, expand, included, selected, element_precedence, maximum_precedence, resource_collection=nil)
    builder = Builder::XmlMarkup.new
    builder.__send__(self.xmlns_qualifier_for(node_name), node_value.resource_header_attributes(node_value, included)) do |element|           
      if (expand != :none) || included.include?(node_name.to_s.camelize(:lower))
        expand = :none if (expand == :immediate_children) 
        node_value.payload_map.each_pair do |child_node_name, child_node_data|
          if child_node_data[:type] == :association
            child_expand = :none
          else
            child_expand = expand
          end
          element << self.generate(child_node_name.to_s.camelize(:lower), child_node_data[:value], child_expand, included, selected, child_node_data[:precedence], maximum_precedence, child_node_data[:resource_collection])
        end
      end
    end
  end
      
  def self.construct_from_array(*params)
    builder = Builder::XmlMarkup.new
    if params[7] #resource_collection
      self.construct_from_sdata_array(*params)
    else
      self.construct_from_non_sdata_array(*params)
    end
  end
  
  def self.construct_from_sdata_array(node_name, node_value, expand, included, selected, element_precedence, maximum_precedence, resource_collection)
    builder = Builder::XmlMarkup.new
    scoped_children_collection = self.sdata_collection_url(resource_collection[:parent], resource_collection[:url])
    builder.__send__(self.xmlns_qualifier_for(node_name), {"xlmns:sdata:url" => scoped_children_collection}) do |element|
      if (expand != :none || included.include?(node_name.to_s.camelize(:lower)))
        expand = :immediate_children if (expand == :none && included.include?(node_name.to_s.camelize(:lower))) && !is_sync?
        node_value.each do |item|
          element << self.generate(item.sdata_node_name, item, expand, included, selected, element_precedence, maximum_precedence, nil)
        end
      end 
    end
  end
      
  def self.construct_from_non_sdata_array(node_name, node_value, expand, included, selected, element_precedence, maximum_precedence, resource_collection)
    builder = Builder::XmlMarkup.new
    builder.__send__(xmlns_qualifier_for(node_name)) do |element|
      expand = :immediate_children if expand == :none 
      node_value.each do |item|
        element << self.generate(node_name.to_s.singularize, item, expand, included, selected, element_precedence, maximum_precedence, (item.is_a?(Hash) ? item[:resource_collection] : nil))
      end
    end          
  end
      
  def self.construct_from_hash(node_name, node_value, expand, included, selected, element_precedence, maximum_precedence, resource_collection)
    builder = Builder::XmlMarkup.new
    builder.__send__(xmlns_qualifier_for(node_name)) do |element|      
      expand = :none if (expand == :immediate_children) 
      node_value.each_pair do |child_node_name, child_node_data|
        element << self.generate(child_node_name.to_s.camelize(:lower), child_node_data, expand, included, selected, element_precedence, maximum_precedence, (child_node_data.is_a?(Hash) ? child_node_data[:resource_collection] : nil))
      end
    end
  end
      
  def self.construct_from_string(node_name, node_value, expand, included, selected, element_precedence, maximum_precedence, resource_collection)
    builder = Builder::XmlMarkup.new
    builder.__send__(self.xmlns_qualifier_for(node_name.to_s.camelize(:lower)), (node_value ? node_value.to_s : {'xlmns:xsi:nil' => "true"})) 
  end

  def self.xmlns_qualifier_for(element)
    "xmlns:crmErp:#{element}"
  end
     
  def self.sdata_collection_url(parent, child)
    $APPLICATION_URL + $SDATA_STORE_PATH + parent.sdata_node_name + "('#{parent.id}')/" + child
  end

  def self.excluded_in_select?(node_name, selected)
    if selected.empty?
      return false
    elsif selected.include?('_root')
      selected.delete '_root'
      return false
    else
      return !selected.include?(node_name.to_s.camelize(:lower))
    end
  end

end