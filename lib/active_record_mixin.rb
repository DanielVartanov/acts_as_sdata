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
          entry.payload = Atom::Content::Payload.new(self.payload(self.sdata_node_name, self))
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
      #TODO: populate self-links for attributes that have them. probably logic is virtual-model-based
      #TODO: security audit for how xml syntax tags from user data are escaped (or not). they should be!

      def payload(node_name, node_value)
        builder = Builder::XmlMarkup.new
        if node_value.is_a?(Array)
          builder.__send__(xmlns_qualifier_for(node_name)) do |element|
            node_value.each do |item|
              element << self.payload(node_name.to_s.singularize, item)
            end                
          end
        elsif node_value.respond_to?('payload_map')
          builder.__send__(node_value.xmlns_qualifier_for(node_name), "xlmns:sdata:key" => node_value.id) do |element|           
            node_value.payload_map.each_pair do |child_node_name, child_node_data|
              element << node_value.payload(child_node_name, child_node_data[:value])
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