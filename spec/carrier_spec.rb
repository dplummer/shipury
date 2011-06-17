require 'spec_helper'

module Shipury
  module TestCarrier
    class Carrier < Shipury::Carrier; end
  end

  describe Carrier do
    context "inherited class" do
      subject { TestCarrier::Carrier.new }

      it "has a correct type attribute" do
        subject[:type].should == "Shipury::TestCarrier::Carrier"
      end
    end
  end
end
