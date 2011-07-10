module Shipury
  class Service < ActiveRecord::Base
    self.store_full_sti_class = true

    set_table_name 'shipury_services'

    belongs_to :carrier, :class_name => 'Shipury::Carrier'

    has_many :rates

    CARRIERS = %(USPS UPS Fedex)

    named_scope :for_select, {
      :joins => :carrier,
      :order => "shipury_carriers.name, shipury_services.name"
    }

    class << self
      def origin(shipping_options)
        opts = { :country     => shipping_options[:sender_country],
                 :state       => shipping_options[:sender_state],
                 :city        => shipping_options[:sender_city],
                 :postal_code => shipping_options[:sender_zip]}
        @origin ||= {}
        unless @origin[opts]
          @origin[opts] = ActiveMerchant::Shipping::Location.new(opts)
        end
        @origin[opts]
      end

      def destination(shipping_options)
        opts = { :country => shipping_options[:country],
                 :postal_code => shipping_options[:zip] }
        @destination ||= {}
        unless @destination[opts]
          @destination[opts] = ActiveMerchant::Shipping::Location.new(opts)
        end
        @destination[opts]
      end

      def package(shipping_options)
        opts = [shipping_options[:weight].to_f * 16, [0,0,0], {:units => :imperial}]
        @package ||= {}
        unless @package[opts]
          @package[opts] = ActiveMerchant::Shipping::Package.new(*opts)
        end
        @package[opts]
      end
    end

    def select_label
      "#{carrier_name} -- #{name}"
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
