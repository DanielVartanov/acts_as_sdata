module SData
  module Exceptions
    module VirtualBase
      class InvalidSDataAttribute < ArgumentError
      end
      class InvalidSDataAssociation < InvalidSDataAttribute
      end
    end
  end
end