module SData
  module AtomContentMixin
    class Payload < Atom::Content::Base
      attribute :type, :'xml:lang'
      def to_xml(*params)
        node = XML::Node.new("sdata:payload")
        p = XML::Parser.string(to_s)
        content = p.parse.root.copy(true)
        node << content
        node
      end
    end
    class Diagnosis < Payload
      def to_xml(*params)
        self[0] #magic done in diagnosis.rb
      end
    end
  end
end
Atom::Content.__send__ :include, SData::AtomContentMixin