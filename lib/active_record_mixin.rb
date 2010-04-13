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
      
      #TODO: change attributes.each_pair to whatever logic is required to decide which attributes to send
      #probably the logic will be virtual model-based
      #TODO: populate self-links for attributes that have them. probably logic is virtual-model-based as well
      def payload
        builder = Builder::XmlMarkup.new
        xml = builder.__send__(self.class.to_s.demodulize.camelize(:lower)) do |payload| 
          self.attributes.each_pair do |name, value|
            if value
              payload.__send__(name) do |element|
                element << value.to_s
              end
            else
              payload.__send__(name, 'xlmns:xsi:nil' => 'true')
            end          
          end
        end
        xml
#        class_title = self.class.to_s.demodulize.camelize(:lower)
#        str = "<#{class_title}>"
#        self.attributes.each_pair do |name, value|
#          str += "<#{name}>#{value}</#{name}>"
#        end
#        str += "</#{class_title}>"
#        str
      end
    end
  end
end
ActiveRecord::Base.extend SData::ActiveRecordMixin