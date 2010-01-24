ActionController::Routing::Routes.draw(:delimiters => ['/', '.', '!', '\(', '\)' ]) do |map|
  map.sdata_resource :items

#  map.connect '/items/create', :controller => 'items', :action => 'create'
  map.connect '/items/:id', :controller => 'items', :action => 'show'

#  map.connect '/items', :controller => 'items', :action => 'index', :conditions => { :method => :get }
  map.connect '/items', :controller => 'items', :action => 'create', :conditions => { :method => :post }

#  map.connect ':controller/:action/:id'
#  map.connect ':controller/:action/:id.:format'
end
