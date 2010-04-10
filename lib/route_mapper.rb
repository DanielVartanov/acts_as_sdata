module SData
  class RouteMapper < Struct.new(:router, :resource_name, :options)
    def map_sdata_routes!
      map_sdata_collection
      map_sdata_collection_with_predicate
      map_sdata_show_instance
      map_sdata_create_instance
      map_sdata_update_instance
    end

  protected

    def map_sdata_collection
      map_route "#{name_in_path}", 'sdata_collection', :get
    end

    def map_sdata_collection_with_predicate
      map_route "#{name_in_path}\\(:predicate\\)", 'sdata_collection', :get
    end

    def map_sdata_show_instance
      map_route "#{name_in_path}/!:instance_id", 'sdata_show_instance', :get
    end

    def map_sdata_create_instance
      map_route "#{name_in_path}", 'sdata_create_instance', :post
    end

    def map_sdata_update_instance
      map_route "#{name_in_path}/!:instance_id", 'sdata_update_instance', :put
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
      @namespace ||= ("#{options[:namespace]}/" || "")
    end

    def controller
      @controller ||= resource_name.to_s.pluralize
    end

    def name_in_path
      @name_in_path ||= resource_name.to_s.camelize.pluralize
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