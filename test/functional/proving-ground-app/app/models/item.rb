class Item < ActiveRecord::Base
  validates_presence_of :name
  acts_as_sdata :title => lambda { "Item '#{name}' (id ##{id})" },
                :summary => lambda { "Item '#{name}' (id ##{id})" },
                :content => :sdata_content,
                :linked => :uuid
                
      
  def sdata_content
    "Item ##{self.id}: #{self.name}"
  end

                
end