module SData
  module ActiveRecordExtensions
    class Base < ::ActiveRecord::Base
      self.abstract_class = true
    end
  end
end