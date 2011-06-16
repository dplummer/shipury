require 'active_record'

ActiveRecord::Base.configurations['root'] = {
  :adapter  => 'sqlite3',
  :database => 'features/shipury_plugin.sqlite3.db'
}

ActiveRecord::Base.establish_connection(
  ActiveRecord::Base.configurations['root'])
