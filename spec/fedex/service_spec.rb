require 'spec_helper'

module Shipury
  module Fedex
    describe Service do
      describe "#download_rates" do
        before(:each) do
          subject.stub(:rate_txt_lines).and_return(rates_txt.split("\n"))
        end

        context "Fedex Ground" do
          subject { Service.new(:name => 'Ground') }

          let(:rates_txt) do
            #removing these tabs will break the tests
            <<-TXT_CONTENT
FedEx Ground Standard List Rates										
"Effective 2/28/2011"										

Weight	US Ground	US Ground	To Puerto Rico
	Zone 2	Zone 3	Zone 17
1	$5.17 	$5.40 	-
2	$5.37 	$5.72 	-
TXT_CONTENT
          end

          it "updates the price for each weight/zone combo" do
            subject.should_receive(:update_weight_zone_rate_price).with(1, 2, 5.17)
            subject.should_receive(:update_weight_zone_rate_price).with(1, 3, 5.4)
            subject.should_receive(:update_weight_zone_rate_price).with(2, 2, 5.37)
            subject.should_receive(:update_weight_zone_rate_price).with(2, 3, 5.72)
            subject.download_rates!
          end
        end

        context "Fedex 2-Day" do
          subject { Service.new(:name => '2-Day') }

          let(:rates_txt) do
            #removing these tabs will break the tests
            <<-TXT_CONTENT
FedEx Express U.S. Package Standard List Rates: FedEx 2Day®										
"Effective 2/28/2011"										

Weight	Zone 2	Zone 3	Zone 11-12
FedEx® Envelope up to 8 oz.	$11.35 	$11.60 	$34.70
1	$11.35 	$11.60 	$34.70
2	$11.50 	$11.85 	$41.50
TXT_CONTENT
          end

          it "updates the price for each weight/zone combo" do
            subject.should_receive(:update_weight_zone_rate_price).with(0.5, 2, 11.35)
            subject.should_receive(:update_weight_zone_rate_price).with(0.5, 3, 11.6)
            subject.should_receive(:update_weight_zone_rate_price).with(0.5, 11, 34.70)
            subject.should_receive(:update_weight_zone_rate_price).with(0.5, 12, 34.70)
            subject.should_receive(:update_weight_zone_rate_price).with(1, 2, 11.35)
            subject.should_receive(:update_weight_zone_rate_price).with(1, 3, 11.6)
            subject.should_receive(:update_weight_zone_rate_price).with(1, 11, 34.70)
            subject.should_receive(:update_weight_zone_rate_price).with(1, 12, 34.70)
            subject.should_receive(:update_weight_zone_rate_price).with(2, 2, 11.5)
            subject.should_receive(:update_weight_zone_rate_price).with(2, 3, 11.85)
            subject.should_receive(:update_weight_zone_rate_price).with(2, 11, 41.50)
            subject.should_receive(:update_weight_zone_rate_price).with(2, 12, 41.50)
            subject.download_rates!
          end
        end

        context "Fedex Express Saver" do
          subject { Service.new(:name => 'Express Saver') }

          let(:rates_txt) do
            #removing these tabs will break the tests
            <<-TXT_CONTENT
FedEx Express U.S. Package Standard List Rates: FedEx Express Saver®										
"Effective 2/28/2011"										

Weight	Zone 2	Zone 3
FedEx® Envelope up to 8 oz.	$10.50 	$10.55
1	$10.50 	$10.55
2	$10.55 	$10.70
TXT_CONTENT
          end

          it "updates the price for each weight/zone combo" do
            subject.should_receive(:update_weight_zone_rate_price).with(0.5, 2, 10.5)
            subject.should_receive(:update_weight_zone_rate_price).with(0.5, 3, 10.55)
            subject.should_receive(:update_weight_zone_rate_price).with(1, 2, 10.5)
            subject.should_receive(:update_weight_zone_rate_price).with(1, 3, 10.55)
            subject.should_receive(:update_weight_zone_rate_price).with(2, 2, 10.55)
            subject.should_receive(:update_weight_zone_rate_price).with(2, 3, 10.7)
            subject.download_rates!
          end
        end

        context "Fedex Overnight" do
          subject { Service.new(:name => 'Overnight') }

          let(:rates_txt) do
            #removing these tabs will break the tests
            <<-TXT_CONTENT
FedEx Express U.S. Package Standard List Rates: FedEx First Overnight®										
"Effective 2/28/2011"										

Weight	Zone 2	Zone 3
FedEx® Envelope up to 8 oz.	$42.85 	$46.25
1	$46.30 	$53.60
2	$46.75 	$55.90


Multiweight/Per-Pound Rates (multiply by total shipment weight)										
"Effective 2/28/2011"										

Weight	Zone 2	Zone 3
100-499	$1.99 	$2.72
TXT_CONTENT
          end

          it "updates the price for each weight/zone combo" do
            subject.should_receive(:update_weight_zone_rate_price).with(0.5, 2, 42.85)
            subject.should_receive(:update_weight_zone_rate_price).with(0.5, 3, 46.25)
            subject.should_receive(:update_weight_zone_rate_price).with(1, 2, 46.3)
            subject.should_receive(:update_weight_zone_rate_price).with(1, 3, 53.6)
            subject.should_receive(:update_weight_zone_rate_price).with(2, 2, 46.75)
            subject.should_receive(:update_weight_zone_rate_price).with(2, 3, 55.9)
            subject.download_rates!
          end
        end
      end

      describe "load_config" do
        subject { Shipury::Fedex::Service }
        describe "default configs" do
          it "loads the label" do
            subject.config[:label].should == 'FedEx'
          end

          it "loads the ActiveShipping config" do
            Set.new(subject.config[:config].keys).
              should == Set.new([:account, :key, :login, :password])
          end
        end
      end

    end
  end
end
