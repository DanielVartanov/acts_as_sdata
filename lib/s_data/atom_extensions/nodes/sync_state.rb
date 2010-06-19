module SData
  module AtomExtensions
    module Nodes # the reason I didn't name this Atom is that I didn't feel like adding :: in a gawdjillion places ATM   
      class SyncState
        def initialize(xml=nil)
        end
        
        def self.parse(xml)
          # no need to parse sync states at this time
        end
      end
    end
  end
end