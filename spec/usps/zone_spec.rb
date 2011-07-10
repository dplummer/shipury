require 'spec_helper'

module Shipury
  module USPS
    describe Zone do
      describe ".download_tables" do
        before(:each) do
          stub_request(:get, Zone::ZONECHART_URL + "005").
            to_return(File.new("spec/shipping_fixtures/zone_chart_005.html"))
        end

        it "creates the correct number of records" do
          Shipury::USPS::Zone.download_tables(StringIO.new, 5, 5)
          Shipury::USPS::Zone.count(:conditions => {:source_zip_gte => 500}).
            should == 168
        end
      end
    end
  end
end
