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
        selected = params[:select].to_s.split(',') + ['_root']
        expand = (included.include?('$children') ? :all_children : :immediate_children)
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
            begin
              entry.payload = Atom::Content::Payload.new(Payload.generate(self.sdata_node_name, self, expand, included, selected, 1, maximum_precedence, nil))
            rescue Exception => e
              entry.diagnosis = Atom::Content::Diagnosis.new(ApplicationDiagnosis.new(:exception => e).to_xml(:entry))
            end
          end
          entry.content = sdata_content
        end
      end

      def sdata_node_name(entity=self.class)
        entity.to_s.demodulize.camelize(:lower)
      end

      def resource_header_attributes(resource, included)
        hash = {}
        hash.merge!({"xlmns:sdata:key" => resource.id, "xlmns:sdata:url" => resource.sdata_resource_url}) if resource.id
        hash.merge!("xlmns:sdata:descriptor" => resource.entry_content) if included.include?("$descriptor")
        hash.merge!("xlmns:sdata:uuid" => resource.uuid.to_s) if resource.respond_to?("uuid") && !resource.uuid.blank?
        hash
      end

      def sdata_resource_url
        $APPLICATION_URL + $SDATA_STORE_PATH + sdata_node_name.pluralize + "('#{self.id}')"
      end

      protected

      def sdata_default_author
        "Billing Boss"
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

    end
  end
end
# Extension of ActiveRecord removed due to refactoring. Now VirtualBase is extended instead.
# Not sure yet if there is a case where we DO need to extend ActiveRecord directly.
# Might considering merging those two classes otherwise.
# RADAR: Tested refactoring, but it could still be buggy if I missed something! Watch out.