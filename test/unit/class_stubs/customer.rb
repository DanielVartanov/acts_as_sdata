class Customer < ModelBase
  
  attr_accessor :id, :created_by, :name, :number, :contacts, :uuid, :created_at, :updated_at
  def populate_defaults
    self.id = @id || object_id.abs
    self.name = @name || "Customer Name"
    self.number = @number || 12345
    self.contacts = @contacts || build_contacts(:number => 2, :created_by => self)
    self.uuid = @uuid || "CUST-123456-654321-000000"
    self.created_at = @created_at || Time.now-2.days
    self.updated_at = @updated_at || Time.now-1.day
    self
  end
  
  def default_contact
    self.contacts[0]
  end

  def created_by_id
    @created_by ? @created_by.id : nil
  end

  def sdata_content
    "Customer ##{self.id}: #{self.name}"
  end
  
  def payload_map(opts={})
    {
      :name                => {:value => @name, :precedence => 2}, 
      :number              => {:value => @number, :precedence => 5},
      :uuid                => {:value => @uuid, :precedence => 2},
      :created_at          => {:value => @created_at, :precedence => 3},
      :updated_at          => {:value => @updated_at, :precedence => 3},
      :my_default_contact  => {:value => self.default_contact, :precedence => 3},
      :my_contacts         => {:value => @contacts, :precedence => 5, :resource_collection => 
                                {:url => 'contacts', :parent => 'customer'}
                              },
      :simple_elements   => {:value => ['element 1', 'element 2'], :precedence => 6},
      :hash     => {:value => {:simple_object_key => 'simple_object_value'}, :precedence => 6}
    }
  end
  
  def build_contacts(options)
    the_contacts = []
    for i in 1..options[:number] do
      c = Contact.new
      c.id = i
      c.customer = options[:created_by]
      the_contacts << c
    end
    the_contacts
  end
end