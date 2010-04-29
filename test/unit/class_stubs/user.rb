class User < ModelBase
  
  attr_accessor :id, :name, :password, :customers, :created_at, :updated_at
  def populate_defaults
    self.id = @id || object_id.abs
    self.name = @name || "username"
    self.password = @password || "user_password"
    self.customers = @customers || build_customers(:number => 3, :created_by => self)
    self.created_at = @created_at || Time.now-2.days
    self.updated_at = @updated_at || Time.now-1.day
    self
  end

  def record_id
    @record ? @record.id : nil
  end

  def sdata_content
    "User ##{self.id}: #{self.name}"
  end
  
  def payload_map(opts={})
    {
      :name                => {:value => @name, :precedence => 2}, 
      :record_id           => {:value => @record_id, :precedence => 2},
      :uuid                => {:value => @uuid, :precedence => 2},
      :created_at          => {:value => @created_at, :precedence => 3},
      :updated_at          => {:value => @updated_at, :precedence => 3}
    }
  end 
  
  protected
  
  def build_customers(options)
    the_customers = []
    for i in 1..options[:number] do
      c = Customer.new
      c.id = i
      c.created_by = options[:created_by]
      the_customers << c
    end
    the_customers
  end  
end