class ModelBase < SData::VirtualBase
  attr_accessor :id
  
  def self.name
    super_name = super
    "SData::Contracts::CrmErp::#{super_name}"
  end

  def attributes
    {}
  end
  
  def sdata_options
    {}
  end
  
end