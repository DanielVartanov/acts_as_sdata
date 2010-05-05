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
          begin
            errors = []
            collection = build_sdata_feed
            atom_entries = []
            sdata_scope.each do |entry|
              begin
                collection.entries << entry.to_atom(params)
              rescue Exception => e
                errors << ApplicationDiagnosis.new(:exception => e).to_xml(:feed)
              end
            end
            #TODO: syntactic sugar if possible (such as diagnosing_errors(&block) which does the dirty work)
            errors.each do |error|
              collection[SData::Namespace::sdata_schemas['sdata'], 'diagnosis'] << error
            end
            populate_open_search_for(collection)
            build_feed_links_for(collection)
            render :xml => collection, :content_type => "application/atom+xml; type=feed"
          rescue Exception => e 
            render :xml => ApplicationDiagnosis.new(:exception => e).to_xml(:root)
          end
        end

        def sdata_show_instance
          instance = model_class.find_by_sdata_instance_id(Predicate.strip_quotes(params[:instance_id]))
          render :xml => instance.to_atom(params), :content_type => "application/atom+xml; type=entry"
        end

        def sdata_create_instance
          new_instance = model_class.new(params[:entry].to_attributes)
          if new_instance.save
            render :xml => new_instance.to_atom(params).to_xml, :status => :created, :content_type => "application/atom+xml; type=entry"
          else
            render :xml => new_instance.errors.to_xml, :status => :bad_request
          end
        end

        def sdata_update_instance
          instance = model_class.find_by_sdata_instance_id(Predicate.strip_quotes(params[:instance_id]))
          response.etag = [instance]
          if request.fresh?(response)
            if instance.update_attributes(params[:entry].to_attributes)
              response.etag = [instance]
              render :xml => instance.to_atom(params).to_xml, :content_type => "application/atom+xml; type=entry"
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
        
        def resource_address
          request.protocol + request.host_with_port + request.path
        end

        def build_feed_links_for(feed)
          feed.links << Atom::Link.new(    
            :rel => 'self', 
            :href => (resource_address + "?#{request.query_parameters.to_param}".chomp('?')), 
            :type => 'applicaton/atom+xml; type=feed', 
            :title => 'Refresh')
          if (records_to_return > 0) && (@total_results > records_to_return)
            feed.links << Atom::Link.new(  
              :rel => 'first', 
              :href => (resource_address + "?#{request.query_parameters.merge(:startIndex => '1').to_param}"), 
              :type => 'applicaton/atom+xml; type=feed', 
              :title => 'First Page')
            #L = (T-1)-((T-1)%P)+1 = (T-1)/P*P+1, L=start index of last page, T=total results, P=results per page 
            feed.links << Atom::Link.new(  
              :rel => 'last', 
              :href => (resource_address + "?#{request.query_parameters.merge(:startIndex => [1,(@last=(((@total_results-zero_based_start_index - 1) / records_to_return * records_to_return) + zero_based_start_index + 1))].max).to_param}"), 
              :type => 'applicaton/atom+xml; type=feed', 
              :title => 'Last Page')
            if (one_based_start_index+records_to_return) <= @total_results
              feed.links << Atom::Link.new(
                :rel => 'next', 
                :href => (resource_address + "?#{request.query_parameters.merge(:startIndex => [1,[@last, (one_based_start_index+records_to_return)].min].max.to_s).to_param}"), 
                :type => 'applicaton/atom+xml; type=feed', 
                :title => 'Next Page')
            end
            if (one_based_start_index > 1)
              feed.links << Atom::Link.new(
                :rel => 'previous', 
                :href => (resource_address + "?#{request.query_parameters.merge(:startIndex => [1,[@last, (one_based_start_index-records_to_return)].min].max.to_s).to_param}"), 
                :type => 'applicaton/atom+xml; type=feed', 
                :title => 'Previous Page')
            end
          end
        end

        def build_sdata_feed
          Namespace.add_feed_extension_namespaces(%w{crmErp sdata http opensearch sle xsi})
          Atom::Feed.new do |f|
            f.title = sdata_options[:feed][:title]
            f.updated = Time.now
            f.authors << Atom::Person.new(:name => sdata_options[:feed][:author])
            f.id = resource_address
            f.categories << Atom::Category.new(:scheme => 'http://schemas.sage.com/sdata/categories',
                                               :term   => 'collection',
                                               :label  => 'Resource Collection')
            # FIXME: the sequence for generating namespace prefixes is abysmal, 
            # but only way I got atom to accept it. it's like taking an english sentence, translating it to 
            # french through an online translator, then to spanish, then back to english, and then using the 
            # resulting english translation instead of your original english sentence... -eugene
            # see namespace_definitions.rb lines 26+ for the other half of this hack
          end
        end

        def records_to_return
          default_items_per_page = sdata_options[:feed][:default_items_per_page] || 10
          maximum_items_per_page = sdata_options[:feed][:maximum_items_per_page] || 100
          #check whether the count param is castable into integer
          return default_items_per_page if params[:count].blank? or (params[:count].to_i.to_s != params[:count])
          items_per_page = [params[:count].to_i, maximum_items_per_page].min
          items_per_page = default_items_per_page if (items_per_page < 0)
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

        #(name eq 'asdf') -> options[:conditions] = ['"name" eq ?', 'asdf']
        def sdata_scope
          options = {}

          if params.key? :predicate
            predicate = SData::Predicate.parse(CGI::unescape(params[:predicate]))
            options[:conditions] = predicate.to_conditions
          end
          
          if sdata_options[:scoping]
            options[:conditions] ||= []
            sdata_options[:scoping].each do |scope|
              scopable = self.send(scope[:object])
              conditions = ["#{scope[:attribute]} = ?", scopable.send(scope[:key])]
              options[:conditions][0] = [options[:conditions].to_a[0], conditions[0]].compact.join(' and ')
              options[:conditions] << conditions[1].to_s
            end
          end
        
          if params.key? :condition
            options[:conditions] ||= []
            if params[:condition] == "$linked" && sdata_options[:model].sdata_options[:link]
              condition = "#{sdata_options[:model].sdata_options[:link]} is not null"
              options[:conditions][0] = [options[:conditions].to_a[0], condition].compact.join(' and ')
            end
          end

          #FIXME: this is an unoptimized solution that may be a bottleneck for large number of matches
          #if user has hundreds of records but requests first 10, we shouldnt load them all into memory
          #but use sql query to count how many exist in total, and then load the first 10 only

          results = sdata_options[:model].all(options)
          @total_results = results.count
          paginated_results = results[zero_based_start_index,records_to_return]
          paginated_results.to_a
        end
        
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