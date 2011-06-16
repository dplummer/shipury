require 'active_record'

ActiveRecord::Base.configurations['root'] = {:adapter => 'sqlite3',
                                          :database => ':memory:'}
ActiveRecord::Base.establish_connection(
  ActiveRecord::Base.configurations['root'])
ActiveRecord::Migration.verbose = false

ActiveRecord::Schema.define do
  create_table :shipury_carriers do |t|
    t.string :name
    t.string :type

    t.timestamps
  end

  create_table :shipury_rates do |t|
    t.integer :service_id
    t.string  :type
    t.decimal :weight_in_lbs, :precision => 10, :scale => 2
    t.integer :zone
    t.decimal :price, :precision => 10, :scale => 2

    t.timestamps
  end

  create_table :shipury_services do |t|
    t.string  :name
    t.string  :average_delivery_time
    t.boolean :international
    t.string  :type
    t.integer :carrier_id
    t.boolean :zone_priced
    t.boolean :weight_priced

    t.timestamps
  end

  create_table :shipury_zones do |t|
    t.string :type
    t.integer :source_zip_gte
    t.integer :source_zip_lte
    t.integer :destination_zip_gte
    t.integer :destination_zip_lte
    t.integer :zone

    t.timestamps
  end
end
