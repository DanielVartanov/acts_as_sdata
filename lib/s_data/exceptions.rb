module SData
  module Exceptions
    module SdUuid
      class NotFound < ArgumentError
      end
    end
    module VirtualBase
      class InvalidSDataAttribute < ArgumentError
      end
      class InvalidSDataAssociation < InvalidSDataAttribute
      end
    end
  end
end