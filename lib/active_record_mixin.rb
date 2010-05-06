module SData
  module ActiveRecordMixin
    def acts_as_sdata(options={})
      cattr_accessor :sdata_options
      self.sdata_options = options
      self.__send__ :include, InstanceMethods
    end

    def find_by_sdata_instance_id(value)
      attribute = self.sdata_options[:instance_id]

      attribute.nil? ?
        self.find(value.to_i) :
        self.first(:conditions => { attribute => value })
    end

    module InstanceMethods
      def to_atom(params=nil)
        params ||= {}
        maximum_precedence = (!params[:precedence].blank? ? params[:precedence].to_i : 100)
        included = params[:include].to_s.split(',')
        expand = (included.include?('$children') ? :all : :immediate_children)
        returning Atom::Entry.new do |entry|

            entry.id = self.sdata_resource_url
            entry.title = entry_title
            entry.updated = self.updated_at
            entry.authors << Atom::Person.new(:name => self.respond_to?('author') ? self.author : sdata_default_author)
            entry.links << Atom::Link.new(:rel => 'self', 
                                          :href => self.sdata_resource_url, 
                                          :type => 'applicaton/atom+xml; type=entry', 
                                          :title => 'Refresh')
            entry.categories << Atom::Category.new(:scheme => 'http://schemas.sage.com/sdata/categories',
                                                   :term   => 'resource',
                                                   :label  => 'Resource')

            if maximum_precedence > 0
              #raise 'entry-level error'
              begin
                entry.payload = Atom::Content::Payload.new(self.payload(self.sdata_node_name, self, expand, included, 1, maximum_precedence))
              rescue Exception => e
                entry.diagnosis = Atom::Content::Diagnosis.new(ApplicationDiagnosis.new(:exception => e).to_xml(:entry))
              end
            end
            entry.content = sdata_content

        end
      end

    protected

      def sdata_default_author
        "Billing Boss"
      end
      def sdata_resource_url()
        $APPLICATION_URL + $SDATA_STORE_PATH + sdata_node_name.pluralize + "('#{self.id}')"
      end

      def sdata_collection_url(parent, id, child)
        $APPLICATION_URL + $SDATA_STORE_PATH + parent.camelize(:lower) + "('#{id}')/" + child
      end

      def entry_title
        title_proc = self.class.sdata_options[:title]
        title_proc ? instance_eval(&title_proc) : default_entity_title
      end

      def default_entity_title
        "#{self.class.name.demodulize.titleize} #{id}"
      end

      def entry_content
        content_proc = self.class.sdata_options[:content]
        content_proc ? instance_eval(&content_proc) : default_entry_content
      end
      
      def default_entry_content
        self.class.name
      end
      
      def xmlns_qualifier_for(element)
        "xmlns:crmErp:#{element}"
      end
      
      def sdata_node_name(entity=self.class)
        entity.to_s.demodulize.camelize(:lower)
      end
      
      def resource_header_attributes(resource, included)
        hash = {"xlmns:sdata:key" => resource.id, "xlmns:sdata:url" => resource.sdata_resource_url}
        hash.merge!("xlmns:sdata:descriptor" => resource.entry_content) if included.include?("$descriptor")
        hash.merge!("xlmns:sdata:uuid" => resource.uuid.to_s) if resource.respond_to?("uuid") && !resource.uuid.blank?
        hash
      end

      def payload(node_name, node_value, expand, included, element_precedence, maximum_precedence, resource_collection=nil)
        return "" if element_precedence > maximum_precedence
        builder = Builder::XmlMarkup.new
        if node_value.respond_to?('payload_map')
          builder.__send__(node_value.xmlns_qualifier_for(node_name), resource_header_attributes(node_value, included)) do |element|           
            if (expand != :none) || included.include?(node_name.to_s.camelize(:lower))
              node_value.payload_map.each_pair do |child_node_name, child_node_data|
                expand = :none if (expand == :immediate_children) 
                element << node_value.payload(child_node_name.to_s.camelize(:lower), child_node_data[:value], expand, included, child_node_data[:precedence], maximum_precedence, child_node_data[:resource_collection])
              end
            end
          end
        elsif node_value.is_a?(Array)
          if resource_collection
            scoped_children_collection = sdata_collection_url(resource_collection[:parent], self.id, resource_collection[:url])
            builder.__send__(xmlns_qualifier_for(node_name), {"xlmns:sdata:url" => scoped_children_collection}) do |element|
              if (expand != :none) || included.include?(node_name.to_s.camelize(:lower))
                expand = :none if (expand == :immediate_children) 
                node_value.each do |item|
                  element << self.payload(node_name.to_s.singularize.camelize(:lower), item, expand, included, element_precedence, maximum_precedence)
                end
              end
            end
          else
            builder.__send__(xmlns_qualifier_for(node_name)) do |element|
              expand = :none if (expand == :immediate_children) 
              node_value.each do |item|
                element << self.payload(node_name.to_s.singularize, item, expand, included, element_precedence, maximum_precedence, (item.is_a?(Hash) ? item[:resource_collection] : nil))
              end
            end            
          end
        elsif node_value.is_a?(Hash)
          builder.__send__(xmlns_qualifier_for(node_name)) do |element|      
            expand = :none if (expand == :immediate_children) 
            node_value.each_pair do |child_node_name, child_node_data|
              element << self.payload(child_node_name.to_s.camelize(:lower), child_node_data, expand, included, element_precedence, maximum_precedence, (child_node_data.is_a?(Hash) ? child_node_data[:resource_collection] : nil))
            end
          end
        else
          builder.__send__(xmlns_qualifier_for(node_name.to_s.camelize(:lower)), (node_value ? node_value.to_s : {'xlmns:xsi:nil' => "true"})) 
        end
      end
      
    end
  end
end
ActiveRecord::Base.extend SData::ActiveRecordMixin