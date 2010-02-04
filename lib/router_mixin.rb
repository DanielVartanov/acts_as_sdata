module SData
  module RouterMixin
    def sdata_resource(name, options={})
      pluralized_name = name.to_s.pluralize
      formatted_paths = options.delete :formatted_paths

      map_sdata_collection(pluralized_name, formatted_paths)
      map_sdata_collection_with_predicate(pluralized_name)
      map_sdata_show_instance(pluralized_name)
      map_sdata_create_instance(pluralized_name, formatted_paths)
      map_sdata_update_instance(pluralized_name)
    end

    def map_sdata_collection(pluralized_name, formatted_paths = false)
      path = formatted_paths ? "/#{pluralized_name}.sdata" : "/#{pluralized_name}"
      connect path, :controller => pluralized_name, :action => 'sdata_collection', :conditions => { :method => :get }
    end

    def map_sdata_collection_with_predicate(pluralized_name)
      path = "/#{pluralized_name}\\(:predicate\\)"
      connect path, :controller => pluralized_name, :action => 'sdata_collection', :conditions => { :method => :get }
    end

    def map_sdata_show_instance(pluralized_name)
      path = "#{pluralized_name}/!:instance_id"
      connect path, :controller => pluralized_name, :action => 'sdata_show_instance', :conditions => { :method => :get }
    end

    def map_sdata_create_instance(pluralized_name, formatted_paths = false)
      path = formatted_paths ? "/#{pluralized_name}.sdata" : "/#{pluralized_name}"
      connect path, :controller => pluralized_name, :action => 'sdata_create_instance', :conditions => { :method => :post }
    end

    def map_sdata_update_instance(pluralized_name)
      path = "#{pluralized_name}/!:instance_id"
      connect path, :controller => pluralized_name, :action => 'sdata_update_instance', :conditions => { :method => :put }
    end
  end
end

ActionController::Routing::RouteSet::Mapper.__send__ :include, SData::RouterMixin