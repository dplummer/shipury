module Shipury
  class Service < ActiveRecord::Base
    set_table_name 'shipury_services'

    belongs_to :carrier, :class_name => 'Shipury::Carrier'

    has_many :rates

    CARRIERS = %(USPS UPS Fedex)

    named_scope :for_select, {
      :joins => :carrier,
      :order => "shipury_carriers.name, shipury_services.name"
    }

    def select_label
      "#{carrier_name} #{name}"
    end

    def carrier_name
      carrier.name
    end

    def quote(shipping_options)
      Rate.by_weight(weight_priced? ? shipping_options[:weight] : nil).
           by_zone(zone_priced? ? zone_lookup(shipping_options) : nil).
           by_service(self).
           first(:order => 'price ASC').try(:price)
    end

    def update_weight_zone_rate_price(weight, zone, price)
      rate = rates.find_or_initialize_by_weight_in_lbs_and_zone(weight, zone)
      self.zone_priced = true
      self.weight_priced = true
      rate.price = price
      rate.save!
      rate
    end

    def update_weight_rate_price(weight, price)
      rate = rates.find_or_initialize_by_weight_in_lbs(weight)
      self.weight_priced = true
      rate.price = price
      rate.save!
      rate
    end

    def update_zone_rate_price(zone, price)
      rate = rates.find_or_initialize_by_zone(zone)
      self.zone_priced = true
      rate.price = price
      rate.save!
      rate
    end

    def update_rate_price(price)
      rate = rates.first || rates.build
      rate.price = price
      rate.save!
      rate
    end

    private
    def oz_to_lb(oz)
      oz.to_f * 0.0625
    end
  end
end
