require 'spec_helper'

module Shipury
  module TestCarrier
    class Service < Shipury::Service; end
  end

  describe Service do
    context "inherited class" do
      subject { TestCarrier::Service.new }

      it "has a correct type attribute" do
        subject[:type].should == "Shipury::TestCarrier::Service"
      end
    end

    describe "#update_weight_zone_rate_price" do
      let(:rate)  { mock("Rate").as_null_object }
      let(:rates) { mock("Rates").as_null_object }
      before(:each) do
        subject.stub(:rates).and_return(rates)
        rates.stub(:find_or_initialize_by_weight_in_lbs_and_zone).
          and_return(rate)
      end

      it "creates a new rate and sets the weight, zone and price" do
        rates.should_receive(:find_or_initialize_by_weight_in_lbs_and_zone).with(1, 1)
        rate.should_receive(:price=).with(5.1)
        subject.update_weight_zone_rate_price(1, 1, 5.10).should == rate
      end

      it "sets the service to zone priced" do
        subject.update_weight_zone_rate_price(1, 1, 5.10)
        subject.should be_zone_priced
      end

      it "sets the service to weight priced" do
        subject.update_weight_zone_rate_price(1, 1, 5.10)
        subject.should be_weight_priced
      end
    end

    describe "#update_weight_rate_price" do
      let(:rate)  { mock("Rate").as_null_object }
      let(:rates) { mock("Rates").as_null_object }
      before(:each) do
        subject.stub(:rates).and_return(rates)
        rates.stub(:find_or_initialize_by_weight_in_lbs).and_return(rate)
      end

      it "creates a new rate and sets the weight and price" do
        rates.should_receive(:find_or_initialize_by_weight_in_lbs).with(1)
        rate.should_receive(:price=).with(5.1)
        subject.update_weight_rate_price(1, 5.10).should == rate
      end

      it "does not set the service to zone priced" do
        subject.update_weight_rate_price(1, 5.10)
        subject.should_not be_zone_priced
      end

      it "sets the service to weight priced" do
        subject.update_weight_rate_price(1, 5.10)
        subject.should be_weight_priced
      end
    end

    describe "#update_zone_rate_price" do
      let(:rate)  { mock("Rate").as_null_object }
      let(:rates) { mock("Rates").as_null_object }
      before(:each) do
        subject.stub(:rates).and_return(rates)
        rates.stub(:find_or_initialize_by_zone).and_return(rate)
      end

      it "creates a new rate and sets the package, zone and price" do
        rates.should_receive(:find_or_initialize_by_zone).with(1)
        rate.should_receive(:price=).with(4.95)
        subject.update_zone_rate_price(1, 4.95).should == rate
      end

      it "sets the service to zone priced" do
        subject.update_zone_rate_price(1, 4.95)
        subject.should be_zone_priced
      end

      it "does not set the service to be weight priced" do
        subject.update_zone_rate_price(1, 4.95)
        subject.should_not be_weight_priced
      end
    end

    describe "#update_rate_price" do
      let(:rate)  { mock("Rate").as_null_object }
      let(:rates) { mock("Rates").as_null_object }
      before(:each) do
        subject.stub(:rates).and_return(rates)
        rates.stub(:first).and_return(rate)
      end

      it "creates a new rate with the price" do
        rates.should_receive(:first)
        rate.should_receive(:price=).with(2.95)
        subject.update_rate_price(2.95).should == rate
      end

      it "does not set the service to be zone priced" do
        subject.update_rate_price(2.95)
        subject.should_not be_zone_priced
      end

      it "does not set the service to be weight priced" do
        subject.update_rate_price(2.95)
        subject.should_not be_weight_priced
      end
    end
  end
end
