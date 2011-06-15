class ShipuryGenerator < Rails::Generator::NamedBase
  def manifest
    record do |m|
      m.migration_template 'migration.rb', 'db/migrate',
        :migration_file_name => 'create_shipury_tables'
    end
  end
end

