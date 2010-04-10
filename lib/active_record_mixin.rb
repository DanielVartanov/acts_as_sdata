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
          entry.summary = entry_summary
          add_attributes(entry)
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

      def add_attributes(entry)
        self.attributes.each_pair do |name, value|
          entry['sdata', name] << value
        end
        #entry['sdata', 'sdata'] << ta.to_xml(true, 'TradingAccount')
      end
    end
  end
end

ActiveRecord::Base.extend SData::ActiveRecordMixin