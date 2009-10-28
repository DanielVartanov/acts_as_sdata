module SData
  module ControllerMixin
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def acts_as_sdata(options)
        cattr_accessor :sdata_options
        self.sdata_options = options
      end
    end

  protected
    
    def build_sdata_feed
      Atom::Feed.new do |f|
        f.title = sdata_options[:feed][:title]
        f.links << Atom::Link.new(:href => 'http://example.com' + sdata_options[:feed][:path])
        f.updated = Time.now
        f.authors << Atom::Person.new(:name => sdata_options[:feed][:author])
        f.id = sdata_options[:feed][:id]
      end
    end

    def sdata_scope
      options = {}

      if params.key? :predicate
        predicate = SData::Predicate.parse(CGI::unescape(params[:predicate]))
        options[:conditions] = predicate.to_conditions
      end

      sdata_options[:model].all(options)
    end
  end
end