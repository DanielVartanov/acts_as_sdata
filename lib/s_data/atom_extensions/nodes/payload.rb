
module SData
  module AtomExtensions
    module Nodes
      class Payload
        attr_accessor :raw_xml
        include Atom::Xml::Parseable
        add_extension_namespace "sdata", SData.config[:schemas][:sdata]
        add_extension_namespace 'sync', SData.config[:schemas][:sync]

        element 'sync:digest', :class => SData::AtomExtensions::Nodes::Digest, :namespace => SData.config[:schemas][:sync]
      
        def initialize(xml=nil)
          # temporary, until have time to add Linking atom extension
          @raw_xml = xml.read_inner_xml
          xml.read
          parse(xml)
        end
        
        def self.parse(xml)
          new(xml)
        end

        def to_xml(*params)
          node = XML::Node.new("sdata:payload")
          node << content
          return node
        end
        
      end
    end
  end
end

