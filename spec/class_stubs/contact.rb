class Contact < ModelBase
  
  attr_writer :customer, :name, :created_at, :updated_at

  def self.descends_from_active_record?
    true
  end

  def baze
    self
  end

  def populate_defaults
    self.id = @id || object_id.abs
    self.name = @name || "Contact Name"
    self.created_at = @created_at || Time.now-2.days
    self.updated_at = @updated_at || Time.now-1.day
    self
  end

  def owner
    @customer.owner
  end
  
  def sdata_content
    "Contact ##{self.id}: #{self.name}"
  end

  define_payload_map  :name                => { :proc => lambda { @name }, :precedence => 2 },
                      :customer_id         => { :proc => lambda { @customer_id }, :precedence => 2 },
                      :created_at          => { :proc => lambda { @created_at }, :precedence => 4 },
                      :updated_at          => { :proc => lambda { @updated_at }, :precedence => 4 }
end