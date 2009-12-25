module SData
  module RouterMixin
    def sdata_resource(name, options={})
      pluralized_name = name.to_s.pluralize
      formatted_collection_path = options.delete :formatted_collection_path

      formatted_collection_path ?
        map_formatted_sdata_collection(pluralized_name) :
        map_sdata_collection(pluralized_name)

      map_sdata_collection_with_predicate(pluralized_name)
      map_sdata_instance(pluralized_name)
    end

    def map_formatted_sdata_collection(pluralized_name)
      connect "/#{pluralized_name}.sdata", :controller => pluralized_name, :action => 'sdata_collection'
    end

    def map_sdata_collection(pluralized_name)
      connect "/#{pluralized_name}", :controller => pluralized_name, :action => 'sdata_collection'
    end

    def map_sdata_collection_with_predicate(pluralized_name)
      connect "/#{pluralized_name}\\(:predicate\\)", :controller => pluralized_name, :action => 'sdata_collection'
    end

    def map_sdata_instance(pluralized_name)
      connect "#{pluralized_name}/!:instance_id", :controller => pluralized_name, :action => 'sdata_instance'
    end
  end
end

ActionController::Routing::RouteSet::Mapper.__send__ :include, SData::RouterMixin