class ActsAsSdataGenerator < Rails::Generator::Base  
  def manifest
    record do |m|
      m.migration_template "migration.rb", 'db/migrate',
                           :migration_file_name => "create_sdata_database_tables"
    end
  end
  
end
