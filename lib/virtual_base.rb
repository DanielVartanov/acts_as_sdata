# Tried using ActiveRecord::BaseWithoutTable, but had problems calling __include__ on it.
# Research if we need features provided by BWT, otherwise use this.

require 'forwardable'

class VirtualBase
  extend Forwardable
  attr_accessor :baze
  def_delegators :baze, :id, :created_at, :updated_at, :save, :update_attributes
  
  def initialize(the_baze, the_type=nil)
    self.baze = the_baze

    if self.respond_to?('sdata_type') && the_type
      self.sdata_type = the_type
    end

    super()
  end

  def self.build_for(data, the_type=nil)
    if data.is_a? Array
      array = []
      data.each do |item|
        array << self.new(item, the_type) if item
      end
      array
    else
      data ? self.new(data, the_type) : nil
    end
  end

  # FIXME: Below methods transfer ActiveRecord methods to the baze. Is there a cleaner way to do this?

  def self.find(*params)
    self.new(self.baze_class.find(*params))
  end

  def self.first(*params)
    self.new(self.baze_class.first(*params))
  end
  
  def self.all(*params)
    virtual_results = []
    results = self.baze_class.all(*params)
    results.each do |result|
      virtual_results << self.new(result)
    end
    virtual_results
  end
end


VirtualBase.extend SData::ActiveRecordMixin