class Customer < ModelBase

  attr_writer :created_by, :name, :number, :contacts, :created_at, :updated_at, :address
  
  def self.is_a?(value)
    # Don't really like doing this but don't see a quick better way
    return true if value == SData::VirtualBase
    super
  end
  def baze
    self
  end
  def populate_defaults
    self.id = @id || object_id.abs
    self.name = @name || "Customer Name"
    self.number = @number || 12345
    self.contacts = @contacts || build_contacts(:number => 2, :created_by => self)
    self.created_at = @created_at || Time.now-2.days
    self.updated_at = @updated_at || Time.now-1.day
    self.address = @address || Address.new(self)
    self
  end
  
  def contacts
    @contacts || []
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
  
  define_payload_map  :name                => { :proc => lambda { @name }, :precedence => 2 },
                      :number              => { :proc => lambda { @number }, :precedence => 5 },
                      :created_at          => { :proc => lambda { @created_at }, :precedence => 3 },
                      :updated_at          => { :proc => lambda { @updated_at }, :precedence => 3 },
                      :my_default_contact  => { :proc => lambda { self.default_contact }, :precedence => 3 },
                      :my_contacts         => { :proc => lambda { @contacts },
                                                :precedence => 5, #treated as a CHILD of customer
                                                :type => :child
                                              },
                      :associated_contacts => { :proc => lambda { @contacts },
                                                :precedence => 3,
                                                :type => :association
                                              }, #treated as an ASSOCIATION of customer
                                              
                      :address             => { :proc => lambda { @address }, :precedence => 5 },

                      :simple_elements     => { :static_value => ['element 1', 'element 2'], :precedence => 6 },

                      :hash_value                => { :static_value => { :simple_object_key => 'simple_object_value' }, :precedence => 6 }

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