require 'spec_helper'

module Shipury
  module TestCarrier
    class Zone < Shipury::Zone; end
  end

  describe Zone do
    context "inherited class" do
      subject { TestCarrier::Zone.new }

      it "has a correct type attribute" do
        subject[:type].should == "Shipury::TestCarrier::Zone"
      end
    end
  end
end
