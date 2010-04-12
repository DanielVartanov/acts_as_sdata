module SData
  module AtomEntryMixin
    def self.included(base)
      base.send :attr_accessor
    end

    def payload=(value)
      self.content = Atom::Content::Xhtml.new(value.to_xml)
    end

    def to_attributes
      attributes = {}
      self['http://sdata.sage.com/schemes/attributes'].each_pair do |name, values|
        attributes[name] = values.first
      end
      attributes
    end
  end
end

Atom::Entry.__send__ :include, SData::AtomEntryMixin