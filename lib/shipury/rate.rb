module Shipury
  class Rate < ActiveRecord::Base
    self.store_full_sti_class = true

    set_table_name 'shipury_rates'

    belongs_to :shipping_service

    named_scope :by_weight, lambda { |weight|
      weight ? {:conditions => ["weight_in_lbs >= ?", weight.to_f]} : {}
    }

    named_scope :by_zone, lambda { |zone|
      zone ? {:conditions => ["zone = ?", zone.to_i]} : {}
    }

    named_scope :by_service, lambda { |service|
      {:conditions => {:service_id => service.id}}
    }
  end
end
