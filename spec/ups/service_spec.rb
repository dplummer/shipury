require 'spec_helper'

module Shipury
  module UPS
    class Service
      describe "load_config" do
        subject { Shipury::UPS::Service }
        describe "default configs" do
          it "loads the label" do
            subject.config[:label].should == 'UPS'
          end

          it "loads the ActiveShipping config" do
            Set.new(subject.config[:config].keys).
              should == Set.new([:key, :login, :password])
          end
        end
      end
    end
  end
end
