module Shipury
  class Carrier < ActiveRecord::Base
    EU_COUNTRY_CODES = %w(GB AT BE BG CY CZ DK EE FI FR DE GR HU IE IT LV LT LU
                          MT NL PL PT RO SK SI ES SE)

    set_table_name 'shipury_carriers'

    validates_uniqueness_of :name
  end
end
