ActionController::Routing::Routes.draw(:delimiters => ['/', '.', '!', '\(', '\)' ]) do |map|
  map.sdata_resource :presidents  
end