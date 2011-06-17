module Shipury
  module Fedex
    class Service < Shipury::Service
      RATE_TXT_FILES = {
        "Ground"                 => "Ground.txt",
        "2-Day"                  => "2Day.txt",
        "Express Saver"          => "ESP.txt",
        "Overnight"              => "FO.txt",
        "Priority Overnight"     => "PO.txt",
        "Standard Overnight"     => "SO.txt"
      }

      belongs_to :carrier, :conditions => {:type => "Shipury::Fedex::Carrier"},
                           :class_name => "Shipury::Fedex::Carrier"

      has_many :rates, :conditions => {:type => "Shipury::Fedex::Rate"},
                       :class_name => "Shipury::Fedex::Rate",
                       :dependent  => :destroy

      validates_inclusion_of :name, :in => RATE_TXT_FILES.keys

      def download_rates!
        require 'net/ftp'

        rate_csv.each do |row|
          (row.headers.length - 1).times do |i|
            parse_cell(row, i + 1)
          end
        end
        save!
      end

      def zone_lookup(shipping_options)
        if name == 'Ground'
          Shipury::Fedex::Zone::Ground.zone_lookup(shipping_options[:sender_zip],
                                                    shipping_options[:zip])
        else
          Shipury::Fedex::Zone::Express.zone_lookup(shipping_options[:sender_zip],
                                                     shipping_options[:zip])
        end
      end

      def parse_cell(row, col)
        # remove the leading $
        if row[col] =~ /^\$?(\d+\.?\d+)\s*$/
          price = $1.to_f
        else
          return
        end

        if row[0] == "FedEx® Envelope up to 8 oz."
          weight = 0.5
        elsif row[0] =~ /^(\d+)( lbs\.)?$/
          weight = $1.to_f
        else
          return
        end

        # Ignore the leading "Zone "
        if row.headers[col] =~ /^(Zone )?(\d+)-?(\d*)\s?$/
          unless $3.blank?
            zone_range = $2.to_i..$3.to_i
          else
            zone = $2.to_f
          end
        elsif row.headers[col] =~ /^(Zone )?(\w)\s?$/
          zone = $2
        else
          return
        end

        if zone_range
          zone_range.each do |zone|
            update_weight_zone_rate_price(weight, zone, price)
          end
        else
          update_weight_zone_rate_price(weight, zone, price)
        end
      end

      def rate_csv
        FasterCSV.new(rate_txt_lines[((name == 'Ground') ? 4 : 3)..-1].join("\n"),
                      :headers     => true,
                      :skip_blanks => true,
                      :col_sep     => "\t")
      end

      def rate_txt_lines
        return @rate_txt_file if @rate_txt_file
        @rate_txt_file = []
        ftp_fedex do |ftp|
          ftp.retrlines("RETR #{RATE_TXT_FILES[name]}") do |line|
            @rate_txt_file << line
          end
        end
        @rate_txt_file
      end

      def ftp_fedex(&block)
        ftp = Net::FTP.new('ftp.fedex.com')
        ftp.login
        ftp.chdir('/pub/us/rates/downloads/documents2')
        yield ftp
      ensure
        ftp.close if ftp
      end
    end
  end
end
