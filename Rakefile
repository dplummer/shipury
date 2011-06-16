require 'rake'
require 'spec/rake/spectask'
require 'init'

desc 'Default: run specs.'
task :default => :spec

desc 'Run the specs'
Spec::Rake::SpecTask.new(:spec) do |t|
  t.spec_opts = ['--colour --format progress --loadby mtime --reverse']
  t.spec_files = FileList['spec/**/*_spec.rb']
end

desc "Seed test data from carriers"
task :seed_test do
  FileUtils.rm('features/shipury_plugin.sqlite3.db')
  ActiveRecord::Base.configurations['root'] = {
    :adapter  => 'sqlite3',
    :database => 'features/shipury_plugin.sqlite3.db'
  }

  ActiveRecord::Base.establish_connection(
    ActiveRecord::Base.configurations['root'])
  ActiveRecord::Migration.verbose = false

  ActiveRecord::Schema.define do
    create_table :shipury_carriers, :force => true do |t|
      t.string :name
      t.string :type

      t.timestamps
    end

    create_table :shipury_rates, :force => true do |t|
      t.integer :service_id
      t.string  :type
      t.decimal :weight_in_lbs, :precision => 10, :scale => 2
      t.integer :zone
      t.decimal :price, :precision => 10, :scale => 2

      t.timestamps
    end

    create_table :shipury_services, :force => true do |t|
      t.string  :name
      t.string  :average_delivery_time
      t.boolean :international
      t.string  :type
      t.integer :carrier_id
      t.boolean :zone_priced
      t.boolean :weight_priced

      t.timestamps
    end

    create_table :shipury_zones, :force => true do |t|
      t.string :type
      t.integer :source_zip_gte
      t.integer :source_zip_lte
      t.integer :destination_zip_gte
      t.integer :destination_zip_lte
      t.integer :zone

      t.timestamps
    end
  end

  Shipury::Fedex::Carrier.download_pricing(STDOUT)
  Shipury::UPS::Carrier.download_pricing(STDOUT)
  Shipury::USPS::Carrier.download_pricing(STDOUT)

  Shipury::Fedex::Zone.download_tables(STDOUT)
  Shipury::UPS::Zone.download_tables(STDOUT)
  Shipury::USPS::Zone.download_tables(STDOUT)
end
