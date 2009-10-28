desc "Load sample fixtures (US presidents) into the current environment's database"
task :load_presidents do
  require File.join(RAILS_ROOT, 'config', 'environment.rb') # TODO: extract to another task or use existing  
  require File.join(RAILS_ROOT, 'spec', 'fixtures', 'load_fixtures.rb')
end