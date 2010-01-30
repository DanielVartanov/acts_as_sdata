ActionController::Base.param_parsers[Mime::Type.lookup('application/atom+xml')] = Proc.new do |data|
  { :entry => Atom::Entry.load_entry(data) }
end