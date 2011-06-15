module Shipury
  module Fedex
    class Rate < Shipury::Rate
      belongs_to :service, :conditions => {:type => "Shipury::Fedex::Service"},
                           :class_name => "Shipury::Fedex::Service"
    end
  end
end
