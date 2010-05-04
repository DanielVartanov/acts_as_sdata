ActionController::Routing::Routes.draw(:delimiters => ['/', '.', '!', '\(', '\)' ]) do |map|
  map.sdata_resource :items
  map.sdata_resource :items, :prefix => '/sdata/example/crmErp/-/'
end