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
          entry.payload = Atom::Content::Payload.new(payload({self.class.to_s.demodulize.camelize(:lower) => self}))
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
      
      def xmlns_qualifier_for(entity)
        "xmlns:crmErp:#{entity.to_s.demodulize.camelize(:lower)}"
      end
      
      #TODO: populate self-links for attributes that have them. probably logic is virtual-model-based
      #TODO: security audit for how xml syntax tags from user data are escaped (or not). they should be!

      def payload(node, options={})
        builder = Builder::XmlMarkup.new
        qualified_attribute = options[:qualified_attribute]
        key = node.keys.first
        value = node.values.first.is_a?(Hash) ? node.values.first[:value] : node.values.first
        if value.is_a?(Array)
          builder.__send__(xmlns_qualifier_for(key)) do |element|
            value.each do |item|
              element << self.payload({key.to_s.singularize => item})
            end                
          end
        elsif value.respond_to?('payload')
          builder.__send__(value.xmlns_qualifier_for(key), "xlmns:sdata:key" => value.id) do |output|           
            value.payload_map.each_key do |name|
              output << value.payload({name => value.payload_map[name]})
            end
          end
        else
          builder.__send__(xmlns_qualifier_for(key), (value ? value.to_s : {'xlmns:xsi:nil' => "true"})) 
        end
      end
      
    end
  end
end
ActiveRecord::Base.extend SData::ActiveRecordMixin

#        class_title = self.class.to_s.demodulize.camelize(:lower)
#        str = "<#{class_title}>"
#        self.attributes.each_pair do |name, value|
#          str += "<#{name}>#{value}</#{name}>"
#        end
#        str += "</#{class_title}>"
#        str