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

  add_index :shipury_carriers, :name

  create_table :shipury_rates do |t|
    t.integer :service_id
    t.string  :type
    t.decimal :weight_in_lbs, :precision => 10, :scale => 2
    t.integer :zone
    t.decimal :price, :precision => 10, :scale => 2

    t.timestamps
  end

  add_index :shipury_rates, :type
  add_index :shipury_rates, :service_id
  add_index :shipury_rates, :weight_in_lbs
  add_index :shipury_rates, :zone

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

  add_index :shipury_services, :type
  add_index :shipury_services, :carrier_id

  create_table :shipury_zones do |t|
    t.string :type
    t.integer :source_zip_gte
    t.integer :source_zip_lte
    t.integer :destination_zip_gte
    t.integer :destination_zip_lte
    t.integer :zone

    t.timestamps
  end

  add_index :shipury_zones,
            [:type, :source_zip_gte, :source_zip_lte, :destination_zip_gte,
              :destination_zip_lte ],
            :unique => true,
            :name => :zip_to_zip
end
