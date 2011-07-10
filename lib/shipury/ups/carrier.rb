# http://www.ups.com/content/us/en/shipping/cost/zones/standard_list_rates.html
module Shipury
  module UPS
    class Carrier < Shipury::Carrier
      RATES_XLS = "http://www.ups.com/media/en/standard_list_rates.xls"
      SERVICE_WORKSHEETS = {
        "Three-Day Select"        => "UPS 3DA Select",
        "Ground"                  => "UPS Ground",
        "Second Day Air"          => "UPS 2DA",
        "Second Day Air A.M."     => "UPS 2DA A.M.",
        "Next Day Air Saver"      => "UPS NDA Saver",
        "Next Day Air"            => "UPS NDA",
        "Next Day Air Early A.M." => "UPS NDA A.M."
      }

      has_many :services, :conditions => {:type => "Shipury::UPS::Service"},
                          :class_name => "Shipury::UPS::Service",
                          :dependent  => :destroy

      def self.context(origin, destination)
        case origin
          when "US"
            destination == "US" ? 'US Domestic' : 'US Origin'
          when "PR"
            'Puerto Rico Origin'
          when "CA"
            'Canada Origin'
          when "MX"
            'Mexico Origin'
          when "PL"
            destination == "PL" ? 'Polish Origin' : 'Other International Origin'
          when *EU_COUNTRY_CODES
            'EU Origin'
          else
            'Other International Origin'
          end
      end

      class << self
        def download_pricing(output_io = StringIO.new)
          carrier = find_or_create_by_name("UPS")
          carrier.download_pricing(output_io)
        end
      end

      def download_pricing(output_io)

        require 'spreadsheet'
        require 'tempfile'
        require 'net/http'
        require 'uri'

        tempfile = "#{Dir::tmpdir}/standard_list_rates.xls"

        url = URI.parse(RATES_XLS)

        File.open(tempfile, 'wb') do |file|
          Net::HTTP.start(url.host, url.port) do |http|
            http.request_get(url.path) do |resp|
              resp.read_body do |segment|
                file.write(segment)
              end
            end
          end
        end

        book = Spreadsheet.open tempfile

        SERVICE_WORKSHEETS.each do |service_name, worksheet_name|
          output_io.puts "Fetching UPS #{service_name}"
          begin
            service_parse(service_name, book.worksheet(worksheet_name))
          rescue => e
            output_io.puts "Error fetching UPS #{service_name}: #{e.message}"
          end
        end

        setup_international_services
      end

      private

      def service_parse(service_name, worksheet)
        service = Shipury::UPS::Service.find_or_initialize_by_name(service_name)
        service.carrier = self
        service.save!
        service.parse_worksheet!(worksheet)
        service.save!
      end
    end
  end
end
