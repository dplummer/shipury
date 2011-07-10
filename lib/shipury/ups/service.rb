module Shipury
  module UPS
    class Service < Shipury::Service
      belongs_to :carrier, :conditions => {:type => "Shipury::UPS::Carrier"},
                           :class_name => "Shipury::UPS::Carrier"

      has_many :rates, :conditions => {:type => "Shipury::UPS::Rate"},
                       :class_name => "Shipury::UPS::Rate",
                       :dependent  => :destroy

      SUPPORTED_SERVICES = ["Three-Day Select",
                            "Ground",
                            "Second Day Air",
                            "Second Day Air A.M.",
                            "Next Day Air Saver",
                            "Next Day Air",
                            "Next Day Air Early A.M."]
      SERVICE_ZONES = {
        "Three-Day Select"        => Shipury::UPS::Zone::ThreeDayAir,
        "Ground"                  => Shipury::UPS::Zone::Ground,
        "Second Day Air"          => Shipury::UPS::Zone::TwoDayAir,
        "Second Day Air A.M."     => Shipury::UPS::Zone::TwoDayAirAM,
        "Next Day Air Saver"      => Shipury::UPS::Zone::NextDayAirSaver,
        "Next Day Air"            => Shipury::UPS::Zone::NextDayAir,
        "Next Day Air Early A.M." => Shipury::UPS::Zone::NextDayAir
      }

      SERVICE_FUEL_SURCHARGE = {
        "Three-Day Select"        => 1.16,
        "Ground"                  => 1.095,
        "Second Day Air"          => 1.16,
        "Second Day Air A.M."     => 1.16,
        "Next Day Air Saver"      => 1.16,
        "Next Day Air"            => 1.16,
        "Next Day Air Early A.M." => 1.16
      }

      class << self
        def active_shipping_quote(name, shipping_options)
          @active_shipping ||= {}
          o = origin(shipping_options)
          d = destination(shipping_options)
          p = package(shipping_options)
          unless @active_shipping[[o,d,p]]
            # TODO: Config file for logins
            ups = ActiveMerchant::Shipping::UPS.new(
                    :login    => 'CHANGEME',
                    :password => 'CHANGEME',
                    :key      => 'CHANGEME')
            @active_shipping[[o,d,p]] = ups.find_rates(o, d, p)
          end

          rate = @active_shipping[[o,d,p]].rates.find { |rate|
            rate.service_name == "UPS #{name}"
          }
          rate ? rate.price.to_f / 100.0 : nil
        end
      end

      def parse_worksheet!(worksheet)
        zone_headings = []
        worksheet.each do |row|
          unless row[2].blank?
            if row[1] == 'Zones'
              zone_headings = row.to_a[2..-1]
            elsif row[1] != 'Price Per Pound'
              zone_headings.each_index do |i|
                weight = if row[1].is_a? String
                           row[1].gsub(/[^\d]/,'').to_f
                         else
                           row[1]
                         end
                update_weight_zone_rate_price(weight,
                                              zone_headings[i],
                                              row[2 + i])
              end
            end
          end
        end
      end

      def zone_lookup(shipping_options)
        SERVICE_ZONES[name].zone_lookup(shipping_options[:sender_zip],
                                        shipping_options[:zip])
      end

      def quote(shipping_options)
        if shipping_options[:sender_state] == 'HI'
          international_quote(shipping_options)
        else
          price = super
          price = (price * SERVICE_FUEL_SURCHARGE[name]).round(2) unless price.nil?
          price
        end
      end

      def international_quote(shipping_options)
        Shipury::UPS::Service.active_shipping_quote(name, shipping_options)
      end
    end
  end
end
