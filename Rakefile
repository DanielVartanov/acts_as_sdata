require 'rake'

begin
  require 'jeweler'

  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "acts_as_sdata"
    gemspec.version = '1.0.0'
    gemspec.authors = ["Daniel Vartanov", "Eugene Gilburg", "Michael Johnston"].sort
    gemspec.email = "dan@vartanov.net"
    gemspec.homepage = "http://sdata.sage.com/"
    gemspec.summary = gemspec.description = "Ruby implementation of SData (Sage Data) protocol"
    gemspec.has_rdoc = false
    gemspec.extra_rdoc_files = ["README.textile"]
  end

  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: gem install jeweler"
end