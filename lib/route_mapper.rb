module SData
  class RouteMapper < Struct.new(:router, :resource_name, :options)
    def map_sdata_routes!
      #RADAR: the order of the below statements makes a difference
      map_sdata_collection
      map_sdata_collection_with_condition_and_predicate
      map_sdata_collection_with_predicate
      map_sdata_collection_with_condition
      map_sdata_show_instance_with_condition
      map_sdata_show_instance
      
      map_sdata_create_instance
      map_sdata_update_instance
    end

    def self.urlize(string)
      string.gsub("'", "(%27|')").gsub("\s", "(%20|\s)")
    end

    protected
    
    CONDITION = urlize("{:condition,([$](linked))}")
    PREDICATE = urlize("{:predicate,[A-z]+\s[A-z]+\s'?[^']*'?}")

    # http://localhost:3000/sdata/billingboss/crmErp/-/tradingAccounts
    def map_sdata_collection
      map_route "#{name_in_path}", 'sdata_collection', :get
    end

    # http://localhost:3000/sdata/billingboss/crmErp/-/tradingAccounts/$linked 
    def map_sdata_collection_with_condition
      map_route "#{name_in_path}\/#{CONDITION}", 'sdata_collection', :get
    end
    
    # http://localhost:3000/sdata/billingboss/crmErp/-/tradingAccounts(name eq 'asdf')   
    # http://localhost:3000/sdata/billingboss/crmErp/-/tradingAccounts(name eq asdf)  
    # http://localhost:3000/sdata/billingboss/crmErp/-/tradingAccounts(name eq '')   
    def map_sdata_collection_with_predicate
      map_route "#{name_in_path}\\(#{PREDICATE}\\)", 'sdata_collection', :get
    end

    # http://localhost:3000/sdata/billingboss/crmErp/-/tradingAccounts/$linked(name eq 'asdf')   
    # http://localhost:3000/sdata/billingboss/crmErp/-/tradingAccounts/$linked(name eq asdf)  
    # http://localhost:3000/sdata/billingboss/crmErp/-/tradingAccounts/$linked(name eq '')   
    def map_sdata_collection_with_condition_and_predicate
      map_route "#{name_in_path}\/#{CONDITION}\\(#{PREDICATE}\\)", 'sdata_collection', :get
    end

    # http://localhost:3000/sdata/billingboss/crmErp/-/tradingAccounts('1')    
    def map_sdata_show_instance
      map_route "#{name_in_path}\\(:instance_id\\)", 'sdata_show_instance', :get
    end

    # http://localhost:3000/sdata/billingboss/crmErp/-/tradingAccounts/$linked('1')    
    def map_sdata_show_instance_with_condition
      map_route "#{name_in_path}/#{CONDITION}\\(:instance_id\\)", 'sdata_show_instance', :get
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
