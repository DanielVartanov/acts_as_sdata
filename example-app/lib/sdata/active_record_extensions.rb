module SData
  module ActiveRecordExtentions
    module InstanceMethods
      def to_atom
        Atom::Entry.new :title => entry_title,
                        :summary => entry_summary                                                
      end

    protected

      def entry_title
        title_proc = self.class.sdata_options[:title]
        title_proc ? instance_eval(&title_proc) : "#{self.class.name}(#{id})"
      end

      def entry_summary
        summary_proc = self.class.sdata_options[:summary]
        summary_proc ? instance_eval(&summary_proc) : self.class.name
      end
    end

    def acts_as_sdata(options={})
      cattr_accessor :sdata_options
      self.sdata_options = options

      self.__send__ :include, InstanceMethods
    end
    
    def find_by_sdata_instance_id(value)
      attribute = self.sdata_options[:instance_id]
      unless attribute.nil?
        self.first :conditions => { attribute => value }
      else
        self.find(value.to_i)
      end
    end
  end
end

ActiveRecord::Base.extend SData::ActiveRecordExtentions