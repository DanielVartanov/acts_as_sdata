require 'rake'

begin
  require 'jeweler'

  PKG_FILES = FileList[ '[a-zA-Z]*', 'lib/**/*', 'spec/**/*' ]
  Jeweler::Tasks.new do |s|
    s.name = "acts_as_sdata"
    s.version = "0.0.1"
    s.authors = ["Daniel Vartanov"]
    s.email = "dan@vartanov.net"
    s.homepage = "http://sdata.sage.com/"
    s.platform = Gem::Platform::RUBY
    s.description = s.summary = "Ruby implementation of SData (Sage Data) protocol"
    s.files = PKG_FILES.to_a
    s.require_path = "lib"
    s.has_rdoc = false
    s.extra_rdoc_files = ["README.textile"]
  end
  Jeweler::GemcutterTasks.new  
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end