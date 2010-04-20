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
      def to_atom
        returning Atom::Entry.new do |entry|
          entry.title = entry_title
          entry.updated = self.updated_at
          entry.authors << Atom::Person.new(:name => self.created_by.sage_username)
          entry.payload = Atom::Content::Payload.new(self.payload(self.sdata_node_name, self, :all, 3, 3))
          entry.content = sdata_content
        end
      end

    protected

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
      #TODO: security audit for how xml syntax tags from user data are escaped (or not). they should be!

      def payload(node_name, node_value, expand, element_priority, minimum_priority )
        return "" if element_priority < minimum_priority
        builder = Builder::XmlMarkup.new
        if node_value.respond_to?('payload_map')
          builder.__send__(node_value.xmlns_qualifier_for(node_name), "xlmns:sdata:key" => node_value.id) do |element|           
            if expand != :none
              node_value.payload_map.each_pair do |child_node_name, child_node_data|
                if (expand == :immediate_children)
                  child_expand = :none
                else
                  child_expand = child_node_data[:expand] || expand
                end
                element << node_value.payload(child_node_name, child_node_data[:value], child_expand, child_node_data[:priority], minimum_priority)
              end
            end
          end
        elsif node_value.is_a?(Array)
          builder.__send__(xmlns_qualifier_for(node_name)) do |element|
            if expand != :none
              expand = :none if expand == :immediate_children
              node_value.each do |item|
                element << self.payload(node_name.to_s.singularize, item, expand, element_priority, minimum_priority)
              end
            end
          end
        elsif node_value.is_a?(Hash)
          builder.__send__(xmlns_qualifier_for(node_name)) do |element|      
            if expand != :none
              expand = :none if expand == :immediate_children
              node_value.each_pair do |child_node_name, child_node_data|
                element << self.payload(child_node_name, child_node_data, expand, element_priority, minimum_priority)
              end
            end
          end
        else
          builder.__send__(xmlns_qualifier_for(node_name), (node_value ? node_value.to_s : {'xlmns:xsi:nil' => "true"})) 
        end
      end
      
    end
  end
end
ActiveRecord::Base.extend SData::ActiveRecordMixin