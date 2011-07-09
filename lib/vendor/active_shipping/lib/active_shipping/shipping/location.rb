module ActiveMerchant #:nodoc:
  module Shipping #:nodoc:
    class Location
      ADDRESS_TYPES = %w{residential commercial po_box}
      
      attr_reader :options,
                  :country,
                  :postal_code,
                  :province,
                  :city,
                  :name,
                  :address1,
                  :address2,
                  :address3,
                  :phone,
                  :fax,
                  :address_type
      
      alias_method :zip, :postal_code
      alias_method :postal, :postal_code
      alias_method :state, :province
      alias_method :territory, :province
      alias_method :region, :province
      
      def initialize(options = {})
        @country = (options[:country].nil? or options[:country].is_a?(ActiveMerchant::Country)) ?
                      options[:country] :
                      ActiveMerchant::Country.find(options[:country])
        @postal_code = options[:postal_code] || options[:postal] || options[:zip]
        @province = options[:province] || options[:state] || options[:territory] || options[:region]
        @city = options[:city]
        @name = options[:name]
        @address1 = options[:address1]
        @address2 = options[:address2]
        @address3 = options[:address3]
        @phone = options[:phone]
        @fax = options[:fax]
        if options[:address_type].present?
          @address_type = options[:address_type].to_s
          unless ADDRESS_TYPES.include?(@address_type)
            raise ArgumentError.new("address_type must be one of #{ADDRESS_TYPES.map(&:inspect).join(', ')}")
          end
        end
      end
      
      def self.from(object, options={})
        return object if object.is_a? ActiveMerchant::Shipping::Location
        attr_mappings = {
          :name => [:name],
          :country => [:country_code, :country],
          :postal_code => [:postal_code, :zip, :postal],
          :province => [:province_code, :state_code, :territory_code, :region_code, :province, :state, :territory, :region],
          :city => [:city, :town],
          :address1 => [:address1, :address, :street],
          :address2 => [:address2],
          :address3 => [:address3],
          :phone => [:phone, :phone_number],
          :fax => [:fax, :fax_number],
          :address_type => [:address_type]
        }
        attributes = {}
        hash_access = begin
          object[:some_symbol]
          true
        rescue
          false
        end
        attr_mappings.each do |pair|
          pair[1].each do |sym|
            if value = (object[sym] if hash_access) || (object.send(sym) if object.respond_to?(sym) && (!hash_access || !Hash.public_instance_methods.include?(sym.to_s)))
              attributes[pair[0]] = value
              break
            end
          end
        end
        attributes.delete(:address_type) unless ADDRESS_TYPES.include?(attributes[:address_type].to_s)
        self.new(attributes.update(options))
      end
      
      def country_code(format = :alpha2)
        @country.nil? ? nil : @country.code(format).value
      end
      
      def residential?; @address_type == 'residential' end
      def commercial?; @address_type == 'commercial' end
      def po_box?; @address_type == 'po_box' end
      
      def to_s
        prettyprint.gsub(/\n/, ' ')
      end
      
      def prettyprint
        chunks = []
        chunks << [@name, @address1,@address2,@address3].reject {|e| e.blank?}.join("\n")
        chunks << [@city,@province,@postal_code].reject {|e| e.blank?}.join(', ')
        chunks << @country
        chunks.reject {|e| e.blank?}.join("\n")
      end
      
      def inspect
        string = prettyprint
        string << "\nPhone: #{@phone}" unless @phone.blank?
        string << "\nFax: #{@fax}" unless @fax.blank?
        string
      end
    end
      
  end
end