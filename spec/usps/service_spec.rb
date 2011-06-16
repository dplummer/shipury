require 'spec_helper'

module Shipury
  module USPS
    describe Service do
      describe "creating new services from csv" do
        describe "#parse_csv" do
          context "Express Mail Flat Rate Envelope service" do
            subject { Service.new(:name => "Express Mail Flat Rate Envelope") }

            let(:csv_content) do
              <<-CSV_CONTENT
Weight Not Over (Pounds),L 1 & 2,3,4,5,6,7,8
0.5,13.25,16.15,19.75,21.35,24.25,25.15,26.65
,,,,,,,
Flat Rate Env,18.30,18.30,18.30,18.30,18.30,18.30,18.30
CSV_CONTENT
            end

            it "updates the price for each zone/price combo" do
              subject.should_receive(:update_zone_rate_price).with(1, 18.3)
              subject.should_receive(:update_zone_rate_price).with(2, 18.3)
              subject.should_receive(:update_zone_rate_price).with(3, 18.3)
              subject.should_receive(:update_zone_rate_price).with(4, 18.3)
              subject.should_receive(:update_zone_rate_price).with(5, 18.3)
              subject.should_receive(:update_zone_rate_price).with(6, 18.3)
              subject.should_receive(:update_zone_rate_price).with(7, 18.3)
              subject.should_receive(:update_zone_rate_price).with(8, 18.3)
              subject.parse_csv(csv_content)
            end
          end
        end

        context "Priority Mail Retail service" do
          subject { Service.new(:name => "Priority Mail Retail") }

          describe "#parse_csv" do
            let(:csv_content) do
              <<-CSV_CONTENT
Weight Not Over (Pounds),L 1 & 2,3,4,5,6,7,8
1,5.10,5.15,5.25,5.35,5.45,5.60,5.95
,,,,,,,
Padded Flat Rate Envelope,4.95,4.95,4.95,4.95,4.95,4.95,4.95
CSV_CONTENT
            end

            before(:each) do
              subject.stub(:update_weight_rate_price)
              subject.stub(:update_zone_rate_price)
            end

            it "updates the price for each weight/zone combo" do
              subject.should_receive(:update_weight_zone_rate_price).with(1, 1, 5.10)
              subject.should_receive(:update_weight_zone_rate_price).with(1, 2, 5.10)
              subject.should_receive(:update_weight_zone_rate_price).with(1, 3, 5.15)
              subject.should_receive(:update_weight_zone_rate_price).with(1, 4, 5.25)
              subject.should_receive(:update_weight_zone_rate_price).with(1, 5, 5.35)
              subject.should_receive(:update_weight_zone_rate_price).with(1, 6, 5.45)
              subject.should_receive(:update_weight_zone_rate_price).with(1, 7, 5.6)
              subject.should_receive(:update_weight_zone_rate_price).with(1, 8, 5.95)
              subject.parse_csv(csv_content)
            end
          end
        end
      end

      describe "#quote" do
        let(:shipping_options) {{
          :country        => 'US',
          :zip            => '98125',
          :sender_zip     => 98125,
          :sender_city    => 'Seattle',
          :sender_state   => 'WA',
          :sender_country => 'US',
          :weight         => 0.5,
          :line_items     => 1
        }}

        context "USPS Media Mail Retail service" do
          let(:carrier) { Carrier.new(:name => 'USPS') }
          subject { Service.new(:name          => "Media Mail Retail",
                                :weight_priced => true,
                                :carrier       => carrier) }
          before(:each) do
            subject.rates.build(:weight_in_lbs => 1,
                                :price         => 2.41)
            subject.rates.build(:weight_in_lbs => 2,
                                :price         => 2.82)
            subject.rates.build(:weight_in_lbs => 3,
                                :price         => 3.23)
            subject.save!
          end

          it "returns the price for a 1 pound package" do
            subject.quote(shipping_options).should == 2.41
          end

          it "returns the price for a 2 pound package" do
            shipping_options[:weight] = 1.5
            subject.quote(shipping_options).should == 2.82
          end
        end
      end
    end
  end
end
