module SData
  module RouterMixin
    def sdata_resource(name)
      pluralized_name = name.to_s.pluralize
      map_sdata_collection(pluralized_name)
      map_sdata_instance(pluralized_name)
    end

    def map_sdata_collection(pluralized_name)
      connect "/#{pluralized_name}(\\(:predicate\\))", :controller => pluralized_name, :action => 'sdata_collection'
    end

    def map_sdata_instance(pluralized_name)
      connect "#{pluralized_name}/!:instance_id", :controller => pluralized_name, :action => 'sdata_instance'
    end
  end
end

ActionController::Routing::RouteSet::Mapper.__send__ :include, SData::RouterMixin