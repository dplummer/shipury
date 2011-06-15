module Shipury
  module USPS
    class Rate < Shipury::Rate
      belongs_to :service, :conditions => {:type => "Shipury::USPS::Service"},
                           :class_name => "Shipury::USPS::Service"
    end
  end
end
