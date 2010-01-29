class Item < ActiveRecord::Base
  acts_as_sdata :title => lambda { "Item '#{name}' (id ##{id})" },
                :summary => lambda { "Item '#{name}' (id ##{id})" }
end