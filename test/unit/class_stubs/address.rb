# VirtualBase is uninitialized for some reason without below line
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

class Address < VirtualBase
  
  attr_accessor :city, :created_at, :updated_at, :owner
  def populate_defaults
    self.city = @city || "Vancouver"
    self.created_at = @created_at || Time.now-2.days
    self.updated_at = @updated_at || Time.now-1.day
    self
  end

  def payload_map_for_customer
    {
      :customer_id         => {:value => @customer_id, :precedence => 2},
      :city                => {:value => @city,        :precedence => 2},
      :created_at          => {:value => @created_at,  :precedence => 4}, 
      :updated_at          => {:value => @updated_at,  :precedence => 4}
    }
  end 
end