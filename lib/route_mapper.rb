module SData
  class RouteMapper < Struct.new(:router, :resource_name, :options)
    def map_sdata_routes!
      map_sdata_collection

      map_sdata_collection_with_condition_and_predicate
      map_sdata_collection_with_predicate
      map_sdata_collection_with_condition
      map_sdata_show_instance_with_condition
      map_sdata_show_instance
      
      map_sdata_create_instance
      map_sdata_update_instance
    end

    protected

    # http://localhost:3000/sdata/billingboss/crmErp/-/tradingAccounts
    def map_sdata_collection
      map_route "#{name_in_path}", 'sdata_collection', :get
    end
    
    #    FIXME: Should be abstracted to:
    # map_route "#{name_in_path}\/{:condition,([$](linked))}", 'sdata_collection', :get
    # because we will need to support other variables than $linked. However, this conflicts with the route 
    # mapping at map_sdata_collection_with_predicate_and_condition. If both methods are abstracted, one of them
    # won't work (the one that won't work depends on which one was mapped first).
    #    Furthermore, map_sdata_collection_with_predicate_and_condition method's route causes THIS method's
    # route to magically assign :conditions => '$linked' in params (doesn't happen if $linked is replaced with 
    # $anything_else in this method. This is very strange and can be a blocker to supporting further variables.

    # http://localhost:3000/sdata/billingboss/crmErp/-/tradingAccounts/$linked 
    def map_sdata_collection_with_condition
      map_route "#{name_in_path}\/$linked", 'sdata_collection', :get
    end
    
    # http://localhost:3000/sdata/billingboss/crmErp/-/tradingAccounts(name eq 'asdf')   
    # http://localhost:3000/sdata/billingboss/crmErp/-/tradingAccounts(name eq asdf)  
    # http://localhost:3000/sdata/billingboss/crmErp/-/tradingAccounts(name eq '')   
    def map_sdata_collection_with_predicate
      map_route "#{name_in_path}\\({:predicate,[A-z]+(%20|\s)[A-z]+(%20|\s)(%27|')?[^']*(%27|')?}\\)", 'sdata_collection', :get
    end

    # http://localhost:3000/sdata/billingboss/crmErp/-/tradingAccounts/$linked(name eq 'asdf')   
    # http://localhost:3000/sdata/billingboss/crmErp/-/tradingAccounts/$linked(name eq asdf)  
    # http://localhost:3000/sdata/billingboss/crmErp/-/tradingAccounts/$linked(name eq '')   
    def map_sdata_collection_with_condition_and_predicate
      map_route "#{name_in_path}\/{:condition,([$](linked))}\\({:predicate,[A-z]+(%20|\s)[A-z]+(%20|\s)(%27|')?[^']*(%27|')?}\\)", 'sdata_collection', :get
    end

    # http://localhost:3000/sdata/billingboss/crmErp/-/tradingAccounts('1')    
    def map_sdata_show_instance
      map_route "#{name_in_path}\\(:instance_id\\)", 'sdata_show_instance', :get
    end

    # http://localhost:3000/sdata/billingboss/crmErp/-/tradingAccounts/$linked('1')    
    def map_sdata_show_instance_with_condition
      map_route "#{name_in_path}/$linked\\(:instance_id\\)", 'sdata_show_instance', :get
    end

    # http://localhost:3000/sdata/billingboss/crmErp/-/tradingAccounts
    def map_sdata_create_instance
      map_route "#{name_in_path}", 'sdata_create_instance', :post
    end

    # http://localhost:3000/sdata/billingboss/crmErp/-/tradingAccounts('1')
    def map_sdata_update_instance
      map_route "#{name_in_path}\\(:instance_id\\)", 'sdata_update_instance', :put
    end

    def map_route(path, action, method)
      path = prefix + path if prefix?
      path = path + ".sdata" if formatted_paths?
      router.connect path, :controller => controller_with_namespace, :action => action, :conditions => { :method => method }
    end

    def controller_with_namespace
      @controller_with_namespace ||= "#{namespace}#{controller}"
    end

    #was: @namespace ||= ("#{options[:namespace]}/" || "")
    #but if options[:namespace] is nil, then "#{nil}/" == "/" == !false,
    #so it'd return "/" instead of "" as required
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
      @prefix ||= (options[:prefix] || '/')
    end

    def prefix?
      !! prefix
    end
  end
end