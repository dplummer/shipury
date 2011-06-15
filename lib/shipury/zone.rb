module Shipury
  class Zone < ActiveRecord::Base
    set_table_name 'shipury_zones'

    validates_numericality_of :source_zip_gte,
                              :only_integer => true,
                              :greater_than_or_equal_to => 0,
                              :less_than    => 100000
    validates_numericality_of :source_zip_lte,
                              :only_integer => true,
                              :greater_than_or_equal_to => 0,
                              :less_than    => 100000
    validates_numericality_of :destination_zip_gte,
                              :only_integer => true,
                              :greater_than_or_equal_to => 0,
                              :less_than    => 100000
    validates_numericality_of :destination_zip_gte,
                              :only_integer => true,
                              :greater_than_or_equal_to => 0,
                              :less_than    => 100000
    validates_numericality_of :zone,
                              :only_integer => true,
                              :greater_than => 0,
                              :less_than    => 1000

    named_scope :lookup_by_zip, lambda { |source, dest|
      {
        :conditions => ["source_zip_gte <= ? AND source_zip_lte >= ? AND " \
                        "destination_zip_gte <= ? AND destination_zip_lte >= ?",
                        source, source, dest, dest],
        :select => 'zone'
      }
    }


    class << self
      def zone_lookup(source_zip, destination_zip)
        lookup_by_zip(source_zip, destination_zip).first.try(:zone)
      end

      def delete_all_for_source(lower, upper)
        delete_all(["source_zip_gte = ? AND source_zip_lte = ?", lower, upper])
      end

      def zip_lowerbound(zip_str)
        case zip_str.length
        when 3
          zip_str + "00"
        when 5
          zip_str
        else
          raise "Not sure what to do with this zip: '#{zip_str}'"
        end
      end

      def zip_upperbound(zip_str)
        case zip_str.length
        when 3
          zip_str + "99"
        when 5
          zip_str
        else
          raise "Not sure what to do with this zip: '#{zip_str}'"
        end
      end
    end
  end
end
