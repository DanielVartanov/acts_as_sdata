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
          entry.payload = Atom::Content::Payload.new(payload)
          entry.content = sdata_content
          #add_headers(entry)
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
      
      def payload_class
        "xmlns:crmErp:#{self.class.to_s.demodulize.camelize(:lower)}"
      end
      
      #TODO: populate self-links for attributes that have them. probably logic is virtual-model-based
      #TODO: security audit for how xml syntax tags from user data are escaped (or not). they should be!

      def payload(node=self, output=nil)
        builder = Builder::XmlMarkup.new
        if node.is_a?(ActiveRecord::Base)
          builder.__send__(payload_class, "xlmns:sdata:key" => self.id) do |output|           
            self.payload_map.each_key do |name|
              self.payload({name => payload_map[name]}, output)
            end
          end
        elsif node.is_a?(Hash) #FIXME: differentiate between object-attr hashes and hashes from the map
          key = node.keys[0]
          value = node.values[0][:value]
          if value
            output.__send__(key) do |element|
              if value.is_a?(ActiveRecord::Base)
                element << value.payload
              else
                if value.is_a?(Array)
                  value.each do |item|
                    element << item.payload
                  end
                else
                  element << value.to_s
                end                
              end
            end
          else
            output.__send__(key, 'xlmns:xsi:nil' => "true") 
          end            
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