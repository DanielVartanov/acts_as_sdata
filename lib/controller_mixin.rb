module SData
  module ControllerMixin
    def acts_as_sdata(options)
      cattr_accessor :sdata_options
      self.sdata_options = options

      self.__send__ :include, InstanceMethods
    end

    module InstanceMethods
      module Actions
        def sdata_collection
          collection = build_sdata_feed
          collection.entries += sdata_scope.map(&:to_atom)
          populate_open_search_for(collection)
          render :xml => collection, :content_type => "application/atom+xml; type=feed"
        end

        def sdata_show_instance
          instance = model_class.find_by_sdata_instance_id(params[:instance_id])
          render :xml => instance.to_atom, :content_type => "application/atom+xml; type=entry"
        end

        def sdata_create_instance
          new_instance = model_class.new(params[:entry].to_attributes)
          if new_instance.save
            render :xml => new_instance.to_atom.to_xml, :status => :created, :content_type => "application/atom+xml; type=entry"
          else
            render :xml => new_instance.errors.to_xml, :status => :bad_request
          end
        end

        def sdata_update_instance
          instance = model_class.find_by_sdata_instance_id(params[:instance_id])
          response.etag = [instance]
          if request.fresh?(response)
            if instance.update_attributes(params[:entry].to_attributes)
              response.etag = [instance]
              render :xml => instance.to_atom.to_xml, :content_type => "application/atom+xml; type=entry"
            else
              render :xml => instance.errors.to_xml, :status => :bad_request
            end
          else
            render :text => nil, :status => :precondition_failed
          end
        end
      end

      module AuxilliaryMethods
        protected

        def model_class
          self.class.sdata_options[:model]
        end

        def build_sdata_feed
          Namespace.add_feed_extension_namespaces(%w{crmErp sdata http opensearch sle xsi})
          Atom::Feed.new do |f|
            f.title = sdata_options[:feed][:title]
            f.links << Atom::Link.new(:href => 'http://example.com' + sdata_options[:feed][:path])
            f.updated = Time.now
            f.authors << Atom::Person.new(:name => sdata_options[:feed][:author])
            f.id = request.protocol + request.host_with_port + request.request_uri
            
            # FIXME: the sequence for generating namespace prefixes is abysmal, 
            # but only way I got atom to accept it. it's like taking an english sentence, translating it to 
            # french through an online translator, then to spanish, then back to english, and then using the 
            # resulting english translation instead of your original english sentence... -eugene
            # see namespace_definitions.rb lines 26+ for the other half of this hack
          end
        end

        def records_to_return
          items_per_page = [params[:itemsPerPage].to_i, sdata_options[:feed][:maximum_items_per_page]].min
          items_per_page = sdata_options[:feed][:default_items_per_page] if (items_per_page < 0)
          items_per_page
        end

        #according to sdata spec startIndex is provided 1-based (not 0-based), 
        #while ruby arrays are 0-based
        #i'm assuming that if user gives us 0 it should stay 0 rather than become -1 and cause problems
        #also we should tell user we started at 0 if he gives us something wrong (e.g. -50 or 'asdf')
        def one_based_start_index
          [(params[:startIndex].to_i), 1].max
        end
        
        def zero_based_start_index
          [(one_based_start_index - 1), 0].max
        end

        def sdata_scope

          options = {}

          if params.key? :predicate
            predicate = SData::Predicate.parse(CGI::unescape(params[:predicate]))
            options[:conditions] = predicate.to_conditions
          end
          #this is an unoptimized solution that may be a bottleneck for large number of matches
          results = sdata_options[:model].all(options)
          @total_results = results.count
          paginated_results = results[zero_based_start_index,records_to_return]
          paginated_results
        end
        
        #test cases (need to write formally). assume :default_items_per_page = 10 and :maximum_items_per_page = 100
        #empty params: itemsPerPage returns 10
        #?itemsPerPage=1: itemsPerPage returns 10
        #?itemsPerPage=20: itemsPerPage returns 20
        #?itemsPerPage=200: itemsPerPage returns 100
        #test cases where startindex or itemsperpage passed is invalid or NaN
        def populate_open_search_for(feed)
            feed[SData::Namespace::sdata_schemas['opensearch'], 'totalResults'] << @total_results
            feed[SData::Namespace::sdata_schemas['opensearch'], 'startIndex'] << one_based_start_index
            feed[SData::Namespace::sdata_schemas['opensearch'], 'itemsPerPage'] << records_to_return
        end
      end
      
      include Actions
      include AuxilliaryMethods
    end
  end
end

ActionController::Base.extend SData::ControllerMixin