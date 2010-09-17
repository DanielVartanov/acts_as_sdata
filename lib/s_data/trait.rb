class Trait < Module
  def self.new(&block)
    mod = super {}
    class << mod
      include ClassMethods
    end
    mod.deferred_block = block
    mod
  end

  module ClassMethods
    attr_accessor :deferred_block

    def included(base)
      base.class_eval &self.deferred_block
    end
  end
end