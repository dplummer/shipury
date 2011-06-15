require 'fastercsv'

module Shipury
  module USPS
    class Service < Shipury::Service
      belongs_to :carrier, :conditions => {:type => "Shipury::USPS::Carrier"},
                           :class_name => "Shipury::USPS::Carrier"

      has_many :rates, :conditions => {:type => "Shipury::USPS::Rate"},
                       :class_name => "Shipury::USPS::Rate",
                       :dependent  => :destroy

      FLAT_RATES = {"Express Mail Flat Rate Envelope"    => "Flat Rate Env",
                    "Priority Mail Flat Rate Envelope"   => "Flat Rate Envs 12-1/2\" x 9-1/2\" or smaller",
                    "Priority Mail Small Flat Rate Box"  => "Small Flat Rate Box",
                    "Priority Mail Medium Flat Rate Box" => "Medium Flat Rate Boxes",
                    "Priority Mail Large Flat Rate Box"  => "Large Flat Rate Box",
                    "Priority Mail APO Flat Rate Box"    => "APO/FPO/DPO Large FRB"}

      def parse_csv(csv_content)
        csv = FasterCSV.new(csv_content, :headers => true, :skip_blanks => true)

        csv.each do |row|
          if weight_zone_headers?(row.headers)
            if FLAT_RATES.keys.include?(name)
              if row[0] == FLAT_RATES[name]
                (1..2).each do |zone|
                  update_zone_rate_price(zone, row[1].to_f)
                end

                (3..8).each do |zone|
                  update_zone_rate_price(zone, row[zone - 1].to_f)
                end
              end
            else
              if row['Weight Not Over (Pounds)'] =~ /\d+/
                weight = row['Weight Not Over (Pounds)'].to_i

                (1..2).each do |zone|
                  update_weight_zone_rate_price(weight, zone, row[1].to_f)
                end

                (3..8).each do |zone|
                  update_weight_zone_rate_price(weight, zone, row[zone - 1].to_f)
                end
              end
            end
          elsif row.headers == ['Weight Not Over (Pounds)', 'Single-Piece']
            update_weight_rate_price(row['Weight Not Over (Pounds)'].to_i,
                                     row['Single-Piece'].to_f)
          elsif row.headers == ['LETTERS', nil, nil, 'FLATS', nil, nil, 'PARCELS', nil]
            case name
            when /Postcard/
              price = row[1]
              update_rate_price(price) if !price.blank? && row[0] == 'Postcard'
            when /Letter/
              if row[0] =~ /\d+/
                update_weight_rate_price(oz_to_lb(row[0]), row[1].to_f)
                @last_oz = row[0].to_f
                @last_price = row[1].to_f
              end
            when /Flat/
              if row[3] =~ /\d+/
                update_weight_rate_price(oz_to_lb(row[3]), row[4].to_f)
                @last_oz = row[3].to_f
                @last_price = row[4].to_f
              end
            when /Parcel/
              if row[6] =~ /\d+/
                update_weight_rate_price(oz_to_lb(row[6]), row[7].to_f)
                @last_oz    = row[6].to_f
                @last_price = row[7].to_f
              end
            end
          else
            puts "#{name}: #{row.headers.join(',')}"
            break
          end
        end
      end

      def zone_lookup(shipping_options)
        Shipury::USPS::Zone.zone_lookup(shipping_options[:sender_zip],
                                         shipping_options[:zip])
      end

      private
      def weight_zone_headers?(row_headers)
        row_headers == ['Weight Not Over (Pounds)', 'L 1 & 2', '3', '4', '5', '6',
          '7', '8'] ||
          row_headers == ['Weight Not Over (Pounds)', 'Zones 1&2', 'Zone 3',
            'Zone 4', 'Zone 5', 'Zone 6', 'Zone 7', 'Zone 8']
      end
    end
  end
end
