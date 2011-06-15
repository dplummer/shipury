module Shipury
  module UPS
    class Rate < Shipury::Rate
      belongs_to :service, :conditions => {:type => "Shipury::UPS::Service"},
                           :class_name => "Shipury::UPS::Service"
    end
  end
end
