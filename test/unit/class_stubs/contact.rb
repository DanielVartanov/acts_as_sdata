class Contact < ModelBase
  
  attr_accessor :id, :customer, :name, :created_at, :updated_at, :uuid
  def populate_defaults
    self.id = @id || object_id.abs
    self.name = @name || "Contact Name"
    self.created_at = @created_at || Time.now-2.days
    self.updated_at = @updated_at || Time.now-1.day
    self
  end

  def customer_id
    @customer ? @customer.id : nil
  end

  def sdata_content
    "Contact ##{self.id}: #{self.name}"
  end

  def payload_map(opts={})
    {
      :name                => {:value => @name, :precedence => 2}, 
      :customer_id         => {:value => @customer_id, :precedence => 2},
      :uuid                => {:value => @uuid, :precedence => 2},
      :created_at          => {:value => @created_at, :precedence => 4}, 
      :updated_at          => {:value => @updated_at, :precedence => 4}
    }
  end 
end