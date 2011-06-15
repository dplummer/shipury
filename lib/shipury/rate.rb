module Shipury
  class Rate < ActiveRecord::Base
    set_table_name 'shipury_rates'

    belongs_to :shipping_service

    named_scope :by_weight, lambda { |weight|
      weight ? {:conditions => ["weight_in_lbs >= ?", weight.to_f]} : {}
    }

    named_scope :by_zone, lambda { |zone|
      zone ? {:conditions => ["zone = ?", zone.to_i]} : {}
    }
  end
end
