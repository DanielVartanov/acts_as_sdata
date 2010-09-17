# SData::VirtualBase is uninitialized for some reason without below line
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

class Address < SData::Resource
  
  def self.descends_from_active_record?
    true
  end
  
  attr_writer :city, :created_at, :updated_at
  attr_accessor :owner
  def populate_defaults
    self.city = @city || "Vancouver"
    self.created_at = @created_at || Time.now-2.days
    self.updated_at = @updated_at || Time.now-1.day
    self
  end

  define_payload_map  :customer_id         => { :proc => lambda { @customer_id }, :precedence => 2 },
                      :city                => { :proc => lambda { @city }, :precedence => 2 },
                      :created_at          => { :proc => lambda { @created_at }, :precedence => 4 },
                      :updated_at          => { :proc => lambda { @updated_at }, :precedence => 4 }

end
