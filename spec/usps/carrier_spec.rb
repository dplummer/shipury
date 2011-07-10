require 'spec_helper'

module Shipury
  module USPS
    describe Carrier do
      context ".download_pricing" do
        subject { Shipury::USPS::Carrier }
        let(:service) { mock("Shipping::USPS::Service").as_null_object }
        let(:base_dir) { 'spec/shipping_fixtures' }
        let(:service_names) do
          ["Priority Mail Retail",
           "Priority Mail Flat Rate Envelope",
           "Priority Mail Small Flat Rate Box",
           "Priority Mail Medium Flat Rate Box",
           "Priority Mail Large Flat Rate Box",
           "Priority Mail APO Flat Rate Box",
           "Express Mail Retail",
           "Express Mail Flat Rate Envelope",
           "First-Class Mail Letter",
           "First-Class Mail Flat",
           "First-Class Mail Parcel",
           "Parcel Post"]
        end

        before(:each) do
          stub_request(:get, Carrier::PRICING_URL).
            to_return(File.new("#{base_dir}/usps_pricing_files.html"))
          stub_request(:get, /http:\/\/(pe|www)\.usps\.com\/prices\/_?csv\/(.*)\.csv/).
              to_return do |request|
            File.new(File.join(base_dir, request.uri.to_s.split('/').last))
          end

          @carrier = Carrier.find_or_create_by_name("USPS")
          @carrier.stub(:setup_international_services)
          Carrier.stub(:find_or_create_by_name).and_return(@carrier)
          Service.stub(:find_or_initialize_by_name).and_return(service)
        end

        it "requests the USPS pricing from the server" do
          subject.download_pricing
          WebMock.should have_requested(:get, Carrier::PRICING_URL)
        end

        it "finds or initializes each shipping service by name" do
          service_names.each do |service_name|
            Service.should_receive(:find_or_initialize_by_name).
              with(service_name).once.ordered
          end
          subject.download_pricing
        end

        it "gets the csv for the shipping service" do
          subject.download_pricing
          WebMock.should have_requested(:get, "http://pe.usps.com/prices/csv/PriorityMail_Retail.csv")
          WebMock.should have_requested(:get, "http://pe.usps.com/prices/csv/ExpressMail_Retail.csv")
          WebMock.should have_requested(:get, "http://www.usps.com/prices/_csv/april172011/FCM-Retail.csv")
          WebMock.should have_requested(:get, "http://www.usps.com/prices/_csv/april172011/Parcel_Post.csv")
        end

        it "sends the contents of the csv file to the service for parsing" do
          service.should_receive(:parse_csv).exactly(service_names.length).times
          service.should_receive(:carrier=).with(@carrier).exactly(service_names.length).times
          subject.download_pricing
        end
      end
    end
  end
end
