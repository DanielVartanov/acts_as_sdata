require 'forwardable'

module SData
  module ActiveRecordExtensions  
    module Mixin
      def acts_as_sdata(options={})
        cattr_accessor :sdata_options
        self.sdata_options = options
        self.__send__ :include, InstanceMethods
        self.__send__ :extend, ClassMethods
      end

      module ClassMethods
      
        def find_by_sdata_instance_id(value)
          attribute = self.sdata_options[:instance_id]

          attribute.nil? ?
            self.find(value.to_i) :
            self.first(:conditions => { attribute => value })
        end

        def sdata_node_name
          @sdata_node_name ||= self.name.demodulize.camelize(:lower)
        end  

        def sdata_contract_name
          @sdata_contract_name ||= SData.sdata_contract_name(self.name)
        end
      
        def sdata_resource_kind_url(dataset)
          #FIXME: will change when we support bk use cases
          postfix = self.sdata_node_name.pluralize
          "#{SData.endpoint}/#{dataset}/#{postfix}"
        end

        def sdata_date(date_time)
          SData::Formatting.format_date_time(date_time)
        end

      end

      module InstanceMethods
        def to_atom(params={}, opts={})
          opts = {
            :atom_show_categories => true,
            :atom_show_links => true,
            :atom_show_authors => true
          }.merge(opts)
          maximum_precedence = (!params[:precedence].blank? ? params[:precedence].to_i : 100)
          included = params[:include].to_s.split(',')
          selected = params[:select].to_s.split(',')
          dataset = params[:dataset] #Maybe || '-' but I don't think it's a good idea to imply a default dataset at this level
          
          query = "?#{clean_params(params).to_query}".chomp('?')
          sync = (params[:sync].to_s == 'true')
          expand = ((sync || included.include?('$children')) ? :all_children : :immediate_children)
          
          returning Atom::Entry.new do |entry|
            entry.id = self.sdata_resource_url(dataset)
            entry.title = entry_title
            entry.updated = self.class.sdata_date(self.updated_at)
            entry.authors << Atom::Person.new(:name => self.respond_to?('author') ? self.author : sdata_default_author)  if opts[:atom_show_authors]
            entry.links << Atom::Link.new(:rel => 'self', 
                                          :href => "#{self.sdata_resource_url(dataset)}#{query}", 
                                          :type => 'application/atom+xml; type=entry', 
                                          :title => 'Refresh') if opts[:atom_show_links] 
            entry.categories << Atom::Category.new(:scheme => 'http://schemas.sage.com/sdata/categories',
                                                     :term   => self.sdata_node_name,
                                                     :label  => self.sdata_node_name.underscore.humanize.titleize) if opts[:atom_show_categories] 
                                                   
            yield entry if block_given?
          
            if maximum_precedence > 0
              begin
                payload = Payload.new(:included => included, 
                                        :selected => selected, 
                                        :maximum_precedence => maximum_precedence, 
                                        :sync => sync,
                                        :contract => self.sdata_contract_name,
                                        :entity => self,
                                        :expand => expand,
                                        :dataset => dataset)
                payload.generate!
                entry.sdata_payload = payload
              rescue Exception => e
                entry.diagnosis = Atom::Content::Diagnosis.new(ApplicationDiagnosis.new(:exception => e).to_xml(:entry))
              end
            end
            entry.content = sdata_content
          end
        end

        def sdata_name
          self.class.name.demodulize
        end

        def sdata_node_name
          self.class.sdata_node_name
        end

        def sdata_resource_url(dataset)
          self.class.sdata_resource_kind_url(dataset) + "('#{self.id}')"
        end

        def resource_header_attributes(dataset, included)
          hash = {}
          hash.merge!({"sdata:key" => self.id, "sdata:url" => self.sdata_resource_url(dataset)}) if self.id
          hash.merge!("sdata:descriptor" => self.entry_content) if included.include?("$descriptor")
          hash.merge!("sdata:uuid" => self.uuid.to_s) if self.respond_to?("uuid") && !self.uuid.blank?
          hash
        end
      
        protected

        def sdata_contract_name
          self.class.sdata_contract_name
        end
        
        def sdata_default_author
          "Billing Boss"
        end

        def entry_title
          title_proc = self.sdata_options[:title]
          title_proc ? instance_eval(&title_proc) : default_entity_title
        end

        def default_entity_title
          "#{self.class.name.demodulize.titleize} #{id}"
        end

        def entry_content
          content_proc = self.sdata_options[:content]
          content_proc ? instance_eval(&content_proc) : default_entry_content
        end
              
        def default_entry_content
          self.class.name
        end
        
        # Thought about passing query_params from controller so wouldn't need this, but it causes other problems
        # (dataset needs to be passed)
        def clean_params(params)
          params.stringify_keys.reject{|key,value|['action','controller','instance_id','dataset'].include?(key)}
        end

      end
    end
  end
end


