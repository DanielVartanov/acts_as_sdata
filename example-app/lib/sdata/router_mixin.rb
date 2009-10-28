module SData
  module RouterMixin
    def sdata_resource(name)
      pluralized_name = name.to_s.pluralize
      map_sdata_collection(pluralized_name)
      map_sdata_instance(pluralized_name)
    end

    def map_sdata_collection(pluralized_name)
      connect "/#{pluralized_name}", :controller => pluralized_name, :action => 'index'
      connect "/#{pluralized_name}\\(:predicate\\)", :controller => pluralized_name, :action => 'index'
    end

    def map_sdata_instance(pluralized_name)
      connect "#{pluralized_name}/!:id", :controller => pluralized_name, :action => 'show'
    end
  end
end

ActionController::Routing::RouteSet::Mapper.__send__ :include, SData::RouterMixin