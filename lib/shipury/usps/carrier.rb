require 'mechanize'

module Shipury
  module USPS
    class Carrier < Shipury::Carrier
      PRICING_URL = "http://www.usps.com/prices/downloadable-pricing-files.htm"
      DOMESTIC_XPATH = 'table[@summary="This table provides current USPS domestic prices, in comma-delimited format"]/tr/td/a'
      SUPPORTED_SERVICES = ["Priority Mail Retail",
                            "Express Mail Retail",
                            "First-Class Mail Retail",
                            "Parcel Post"]
      FIRST_CLASS_SERVICES = ["First-Class Mail Letter",
                              "First-Class Mail Flat",
                              "First-Class Mail Parcel"]
      EXPRESS_MAIL_SERVICES = ["Express Mail Retail",
                               "Express Mail Flat Rate Envelope"]
      PRIORITY_MAIL_SERVICES = ["Priority Mail Retail",
                                "Priority Mail Flat Rate Envelope",
                                "Priority Mail Small Flat Rate Box",
                                "Priority Mail Medium Flat Rate Box",
                                "Priority Mail Large Flat Rate Box",
                                "Priority Mail APO Flat Rate Box"]
      FLAT_RATE_SERVICES = {"First-Class Mail Retail" => FIRST_CLASS_SERVICES,
                            "Express Mail Retail"     => EXPRESS_MAIL_SERVICES,
                            "Priority Mail Retail"    => PRIORITY_MAIL_SERVICES}

      has_many :services, :conditions => {:type => "Shipury::USPS::Service"},
                          :class_name => "Shipury::USPS::Service",
                          :dependent  => :destroy

      class << self
        def context(origin, destination = nil)
          (origin == "US") ? "Domestic" : "International"
        end

        def download_pricing(output_io = StringIO.new)
          carrier = Shipury::USPS::Carrier.find_or_create_by_name("USPS")
          carrier.download_pricing(output_io)
        end
      end

      def download_pricing(output_io = StringIO.new)
        # Get a list of services -> file names
        domestic_service_names.each do |name|
          output_io.puts "Fetching #{name}"

          begin
            if FLAT_RATE_SERVICES.keys.include?(name)
              FLAT_RATE_SERVICES[name].each do |service_name|
                service_download(service_name, name)
              end
            else
              service_download(name)
            end
          rescue Mechanize::ResponseCodeError => e
            output_io.puts "Error fetching csv for #{name}: #{e.message}"
          end
        end
      end

      private

      def service_download(name, link_name = nil)
        link_name ||= name
        service = Shipury::USPS::Service.find_or_initialize_by_name(name)
        service.carrier = self
        service.save!
        service.parse_csv(csv_file_for_service(link_name))
        service.save!
      end

      def agent
        @agent ||= Mechanize.new
      end

      def pricing_page
        @pricing_page ||= agent.get(PRICING_URL)
      end

      def domestic_service_names
        pricing_page.search(DOMESTIC_XPATH).map(&:content) & SUPPORTED_SERVICES
      end

      def csv_file_for_service(name)
        @csv_file ||= {}
        return @csv_file[name] if @csv_file[name]
        @csv_file[name] = pricing_page.link_with(:text => name).click.content.
          split("\n").map(&:rstrip)[2..-1].join("\n")
      end
    end
  end
end
