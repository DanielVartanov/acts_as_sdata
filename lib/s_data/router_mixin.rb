module SData
  module RouterMixin
    def sdata_resource(name, options={})
      route_creator = SData::RouteMapper.new(self, name, options)
      route_creator.map_sdata_routes!
    end
  end
end

ActionController::Routing::RouteSet::Mapper.__send__ :include, SData::RouterMixin