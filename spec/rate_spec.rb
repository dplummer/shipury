require 'spec_helper'

module Shipury
  module TestCarrier
    class Rate < Shipury::Rate; end
  end

  describe Rate do
    context "inherited class" do
      subject { TestCarrier::Rate.new }

      it "has a correct type attribute" do
        subject[:type].should == "Shipury::TestCarrier::Rate"
      end
    end
  end
end
