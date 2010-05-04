ActionController::Routing.module_eval "remove_const(:Routes); Routes = Usher::Interface.for(:rails23)"

ActionController::Routing::Routes.draw(:delimiters => ['/', '.', '!', '\(', '\)' ]) do |map|
  map.sdata_resource :items
  map.sdata_resource :items, :prefix => '/sdata/example/crmErp/-/'
end
