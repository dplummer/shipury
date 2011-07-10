module Shipury
  module Fedex
    class Carrier < Shipury::Carrier
      has_many :services, :conditions => {:type => "Shipury::Fedex::Service"},
                          :class_name => "Shipury::Fedex::Service",
                          :dependent  => :destroy

      class << self
        def download_pricing(output_io = StringIO.new)
          carrier = find_or_create_by_name("Fedex")
          carrier.download_pricing(output_io)
        end
      end

      def download_pricing(output_io)
        supported_services.each do |service_name|
          output_io.puts "Fetching Fedex #{service_name}"
          begin
            service_download(service_name)
          rescue => e
            output_io.puts "Error fetching Fedex #{service_name}: #{e.message}"
          end
        end

        setup_international_services
      end

      private
      def service_download(service_name)
        service = Shipury::Fedex::Service.find_or_initialize_by_name(service_name)
        service.carrier = self
        service.save!
        service.download_rates!
      end

      def supported_services
        Shipury::Fedex::Service::RATE_TXT_FILES.keys
      end
    end
  end
end
