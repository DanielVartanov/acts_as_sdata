
module SData
  module AtomEntryMixin
    Atom::Entry.element :payload, :class => Atom::Content
    def self.included(base)
      base.send :attr_accessor
    end
  end
end

Atom::Entry.__send__ :include, SData::AtomEntryMixin