require 'spec_helper'

module Shipury
  module UPS
    describe Zone do
      describe ".download_tables" do
        context "continental us" do
          before(:each) do
            stub_request(:get, "http://www.ups.com/media/us/currentrates/zone-csv/980.xls").
              to_return(File.new("spec/shipping_fixtures/ups_zone_980.xls"))
          end
        end

        context "hawaii source" do
          before(:each) do
            stub_request(:get, "http://www.ups.com/media/us/currentrates/zone-csv/967.xls")
            stub_request(:get, "http://www.ups.com/media/us/currentrates/zone-csv/968.xls")
            stub_request(:get, "http://www.ups.com/media/en/hiz_hi.csv")
            stub_request(:get, "http://www.ups.com/media/en/hiz_ak.csv")
            stub_request(:get, "http://www.ups.com/media/en/hiz_48pr.csv").
              to_return(File.new("spec/shipping_fixtures/hiz_48pr.csv"))
            Zone::Ground.stub(:create_from_hawaii)
            Zone::TwoDayAir.stub(:create_from_hawaii)
            Zone::TwoDayAirAM.stub(:create_from_hawaii)
            Zone::NextDayAirSaver.stub(:create_from_hawaii)
            Zone::NextDayAir.stub(:create_from_hawaii)
            Zone::NextDayAirAM.stub(:create_from_hawaii)
          end

          it "parses the continental correctly" do
            Zone::Ground          . should_receive(:create_from_hawaii).
                                    with(400..599, "8")
            Zone::TwoDayAir       . should_receive(:create_from_hawaii).
                                    with(400..599, "14")
            Zone::TwoDayAirAM     . should_receive(:create_from_hawaii).
                                    with(400..599, "18")
            Zone::NextDayAirSaver . should_receive(:create_from_hawaii).
                                    with(400..599, "152")
            Zone::NextDayAir      . should_receive(:create_from_hawaii).
                                    with(400..599, "142")
            Zone::NextDayAirAM    . should_receive(:create_from_hawaii).
                                    with(400..599, "142")
            Shipury::UPS::Zone.download_tables(StringIO.new, 967, 968)
          end
        end
      end
    end
  end
end
