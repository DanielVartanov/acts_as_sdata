module SData
  class RouteMapper < Struct.new(:router, :resource_name, :options)
    def map_sdata_routes!
      #RADAR: the order of the below statements makes a difference

      map_sdata_show_instance
      map_sdata_show_instance_with_condition_and_predicate
      map_sdata_show_instance_with_condition
      map_sdata_show_instance_with_predicate

      map_sdata_create_link
      map_sdata_create_instance
      map_sdata_update_instance
      
      map_sdata_sync_source
      map_sdata_sync_source_status
      map_sdata_sync_source_delete
      map_sdata_receive_sync_results

      map_sdata_collection_with_condition
      map_sdata_collection
    end

    def self.urlize(string)
      string.gsub("'", "(%27|')").gsub("\s", "(%20|\s)")
    end

    protected
    
    CONDITION = urlize("{:condition,([$](linked))}")
    PREDICATE = urlize("{:predicate,[A-z]+\s[A-z]+\s'?[^']*'?}")

    TRACKING_ID = urlize("{:trackingID,'[^']+'}")

    # http://localhost:3000/sdata/billingboss/crmErp/-/tradingAccounts
    def map_sdata_collection
      map_route "#{name_in_path}", 'sdata_collection', :get
    end

    # http://localhost:3000/sdata/billingboss/crmErp/-/tradingAccounts/$syncSource('someid')
    def map_sdata_sync_source_status
      map_route "#{name_in_path}\/$syncSource\\(:trackingID\\)", 'sdata_collection_sync_feed_status', :get
    end

    # http://localhost:3000/sdata/billingboss/crmErp/-/tradingAccounts/$syncSource
    def map_sdata_sync_source_delete
      map_route "#{name_in_path}\/$syncSource\\(:trackingID\\)", 'sdata_collection_sync_feed_delete', :delete
    end

    # http://localhost:3000/sdata/billingboss/crmErp/-/tradingAccounts/$linked 
    def map_sdata_collection_with_condition
      map_route "#{name_in_path}\/#{CONDITION}", 'sdata_collection', :get
    end

    # http://localhost:3000/sdata/billingboss/crmErp/-/tradingAccounts('1')    
    def map_sdata_show_instance
      map_route "#{name_in_path}\\(:instance_id\\)", 'sdata_show_instance', :get
    end

    # http://localhost:3000/sdata/billingboss/crmErp/-/tradingAccounts/$linked('1')    
    def map_sdata_show_instance_with_condition
      map_route "#{name_in_path}/#{CONDITION}\\(:instance_id\\)", 'sdata_show_instance', :get
    end

    # http://localhost:3000/sdata/billingboss/crmErp/-/tradingAccounts(name eq 'asdf')
    # http://localhost:3000/sdata/billingboss/crmErp/-/tradingAccounts(name eq asdf)
    # http://localhost:3000/sdata/billingboss/crmErp/-/tradingAccounts(name eq '')
    def map_sdata_show_instance_with_predicate
      map_route "#{name_in_path}\\(#{PREDICATE}\\)", 'sdata_show_instance', :get
    end

    # /$linked(name eq 'Second')
    def map_sdata_show_instance_with_condition_and_predicate
      map_route "#{name_in_path}/#{CONDITION}\\(#{PREDICATE}\\)", 'sdata_show_instance', :get
    end

    # http://localhost:3000/sdata/billingboss/crmErp/-/tradingAccounts
    def map_sdata_create_instance
      map_route "#{name_in_path}", 'sdata_create_instance', :post
    end

    # http://localhost:3000/sdata/billingboss/crmErp/-/tradingAccounts/$linked
    def map_sdata_create_link
      map_route "#{name_in_path}/#{CONDITION}", 'sdata_create_link', :post
    end

    # http://localhost:3000/sdata/billingboss/crmErp/-/tradingAccounts('1')
    def map_sdata_update_instance
      map_route "#{name_in_path}\\(:instance_id\\)", 'sdata_update_instance', :put
    end

    # http://localhost:3000/sdata/billingboss/crmErp/-/tradingAccounts/$syncSource
    def map_sdata_sync_source
      map_route "#{name_in_path}/$syncSource", 'sdata_collection_sync_feed', :post
    end

    # http://localhost:3000/sdata/billingboss/crmErp/-/tradingAccounts/$syncResults
    def map_sdata_receive_sync_results
      map_route "#{name_in_path}/$syncResults\\(:trackingID\\)", 'sdata_collection_sync_results', :post
    end


    def map_route(path, action, method)
      path = prefix.chomp('/') + '/' + path if prefix?
      path = path + ".sdata" if formatted_paths?

      router.connect path, :controller => controller_with_namespace, :action => action, :conditions => { :method => method }, :priority => 99
    end

    def controller_with_namespace
      @controller_with_namespace ||= "#{namespace}#{controller}"
    end

    def namespace
      @namespace ||= (options[:namespace] ? "#{options[:namespace]}/" : "")
    end

    def controller
      @controller ||= resource_name.to_s.pluralize
    end

    def name_in_path
      @name_in_path ||= resource_name.to_s.camelize(:lower).pluralize
    end

    def formatted_paths?
      @formatted_paths ||= options[:formatted_paths]
    end

    def prefix
      if options[:prefix]
        @prefix = options[:prefix] + '/{:dataset,([^\/]+)}'   
      else
        @prefix = '/'
      end
    end

    def prefix?
      !! prefix
    end

  end
end
