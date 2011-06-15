module Shipury
  module UPS
    class Zone < Shipury::Zone
      class Ground          < Shipury::UPS::Zone; end
      class ThreeDayAir     < Shipury::UPS::Zone; end
      class TwoDayAir       < Shipury::UPS::Zone; end
      class TwoDayAirAM     < Shipury::UPS::Zone; end
      class NextDayAirSaver < Shipury::UPS::Zone; end
      class NextDayAir      < Shipury::UPS::Zone; end
      class NextDayAirAM    < Shipury::UPS::Zone; end

      HAWAII_SOURCE_GTE = 96700
      HAWAII_SOURCE_LTE = 96899
      ALASKA_SOURCE_GTE = 99500
      ALASKA_SOURCE_LTE = 99999

      class << self
        def download_tables(output_io = StringIO.new, start_zip = 10, finish_zip = 999)
          require 'open-uri'

          from_continental_us(output_io, start_zip, finish_zip)

          if start_zip * 100 <= HAWAII_SOURCE_GTE && (finish_zip + 1) * 100 > HAWAII_SOURCE_LTE
            delete_all_for_source(HAWAII_SOURCE_GTE, HAWAII_SOURCE_LTE)
            hawaii_to_continental
            hawaii_intra_ground
            hawaii_to_alaska
          end

          if start_zip * 100 <= ALASKA_SOURCE_GTE && (finish_zip + 1) * 100 > ALASKA_SOURCE_LTE
            delete_all_for_source(ALASKA_SOURCE_GTE, ALASKA_SOURCE_LTE)
            alaska_air_continental
            alaska_air_alaska
            alaska_extended
            alaska_ground_continental
            alaska_ground_alaska
          end
        end

        protected
        def create_from_row(source_lower, source_upper, dest_gte, dest_lte, zone)
          return unless zone =~ /^\d+$/
          create(:source_zip_gte      => source_lower,
                 :source_zip_lte      => source_upper,
                 :destination_zip_gte => dest_gte,
                 :destination_zip_lte => dest_lte,
                 :zone                => zone)
        end

        def create_from_hawaii(dest_range, zone)
          create_from_row(HAWAII_SOURCE_GTE, HAWAII_SOURCE_LTE, dest_range.begin,
                          dest_range.end, zone)
        end

        def create_from_alaska(dest_range, zone)
          create_from_row(ALASKA_SOURCE_GTE, ALASKA_SOURCE_LTE, dest_range.begin,
                          dest_range.end, zone)
        end

        private
        def get_source_range(doc)
          frag = doc.css("td").detect{|td| td.content =~ /originating/}
          if frag.try(:content) =~ /Codes\s+([\d-]{6})\s+to\s+([\d-]{6})/
            return zip_lowerbound($1.delete('-')), zip_upperbound($2.delete('-'))
          end
        end

        def destination_range(lower, upper)
          upper ||= lower
          return zip_lowerbound(lower), zip_upperbound(upper)
        end

        def open_and_strip(url)
          open(url).lines.map(&:rstrip).join("\n")
        end

        def from_csv(url, headers, &block)
          csv = FasterCSV.new(open_and_strip(url),
                              :headers => headers,
                              :skip_blanks => true)

          csv.each do |row|
            if row['ZIP Codes'] =~ /^(\d+)-?(\d*)$/
              yield(ups_zone_range($1, $2), row)
            end
          end
        end

        def from_continental_us(output_io = StringIO.new, start_zip = 10, finish_zip = 999)
          (start_zip..finish_zip).each do |zip|
            url = "http://www.ups.com/media/us/currentrates/zone-csv/%03d.xls" % zip
            begin
              doc = Nokogiri::HTML(open(url))
              source_zip_gte, source_zip_lte = get_source_range(doc)

              delete_all_for_source(source_zip_gte, source_zip_lte)

              # Continental US
              doc.css("tr").each do |tr|
                tds = tr.css("td").map(&:content)
                if tds[0] =~ /^(\d{3})-?(\d{3})?$/
                  dest_zip_gte, dest_zip_lte = destination_range($1, $2)

                  Ground.create_from_row(source_zip_gte, source_zip_lte,
                                         dest_zip_gte, dest_zip_lte, tds[1])

                  ThreeDayAir.create_from_row(source_zip_gte, source_zip_lte,
                                         dest_zip_gte, dest_zip_lte, tds[2])

                  TwoDayAir.create_from_row(source_zip_gte, source_zip_lte,
                                         dest_zip_gte, dest_zip_lte, tds[3])

                  TwoDayAirAM.create_from_row(source_zip_gte, source_zip_lte,
                                         dest_zip_gte, dest_zip_lte, tds[4])

                  NextDayAirSaver.create_from_row(source_zip_gte, source_zip_lte,
                                         dest_zip_gte, dest_zip_lte, tds[5])

                  NextDayAir.create_from_row(source_zip_gte, source_zip_lte,
                                         dest_zip_gte, dest_zip_lte, tds[6])
                end
              end

              # To Hawaii and Alaska
              tds = doc.css('td').to_a

              zones = []

              tds.each_index do |i|
                if matches = tds[i].content.match(/^(\[\d\])?\s[a-zA-Z\s\r\n,]+Zone\s(\d+)\s[a-zA-Z\s\r\n,]+Zone\s(\d+)\s[a-zA-Z\s\r\n,]+Zone\s(\d+) for 2nd Day Air(:|.)$/)
                  zones << HI_AK_Zips.new(matches[2], matches[3], matches[4])
                elsif !zones.blank?
                  zones.last.zips << tds[i].content.to_i unless tds[i].content.blank?
                end
              end

              zones.each do |zone|
                zone.each_range do |dest_zip_gte, dest_zip_lte|
                  Ground.create_from_row(source_zip_gte, source_zip_lte,
                                         dest_zip_gte, dest_zip_lte, zone.ground)
                  TwoDayAir.create_from_row(source_zip_gte, source_zip_lte,
                                            dest_zip_gte, dest_zip_lte, zone.second_day_air)
                  NextDayAir.create_from_row(source_zip_gte, source_zip_lte,
                                             dest_zip_gte, dest_zip_lte, zone.next_day_air)
                end
              end

              output_io.puts "\nDone with zone %03d\n" % zip
            rescue OpenURI::HTTPError => e
              output_io.puts "\Skipping zone %03d (%s)\n" % [ zip, e.message ]
              next
            end
          end
        end

        # From Alaska 99500-99999
        # http://www.ups.com/content/us/en/shipping/cost/zones/alaska.html
        # 
        def alaska_air_continental
          csv = FasterCSV.new(open_and_strip("http://www.ups.com/media/en/akz_48.csv"),
                              :headers => ['Services', 'Zones'],
                              :skip_blanks => true)

          csv.each do |row|
            if row['Services'] =~ /^UPS Next Day Air Early A\.M\./
              NextDayAirAM.create_from_alaska(0..96699, row['Zones'])
              NextDayAirAM.create_from_alaska(96800..99499, row['Zones'])
            elsif row['Services'] =~ /^UPS Next Day Air Saver/
              NextDayAirSaver.create_from_alaska(0..96699, row['Zones'])
              NextDayAirSaver.create_from_alaska(96800..99499, row['Zones'])
            elsif row['Services'] =~ /^UPS Next Day Air/
              NextDayAir.create_from_alaska(0..96699, row['Zones'])
              NextDayAir.create_from_alaska(96800..99499, row['Zones'])
            elsif row['Services'] =~ /^UPS 2nd Day Air A\.M\./
              TwoDayAirAM.create_from_alaska(0..96699, row['Zones'])
              TwoDayAirAM.create_from_alaska(96800..99499, row['Zones'])
            elsif row['Services'] =~ /^UPS 2nd Day Air/
              TwoDayAir.create_from_alaska(0..96699, row['Zones'])
              TwoDayAir.create_from_alaska(96800..99499, row['Zones'])
            end
          end
        end
     
        def alaska_air_alaska
          from_csv("http://www.ups.com/media/en/akz_air.csv",
              ['ZIP Codes', 'Next Day Air']) do |dest_zip_range, row|
            NextDayAir.create_from_alaska(dest_zip_range, row['Next Day Air'])
            NextDayAirAM.create_from_alaska(dest_zip_range, row['Next Day Air'])
          end
        end

        def alaska_extended
          from_csv("http://www.ups.com/media/en/akz_hi.csv",
              ['ZIP Codes', 'Next Day Air', '2nd Day Air',
               'Ground']) do |dest_zip_range, row|
            Ground.create_from_alaska(dest_zip_range, row['Ground'])
            TwoDayAir.create_from_alaska(dest_zip_range, row['2nd Day Air'])
            TwoDayAirAM.create_from_alaska(dest_zip_range, row['2nd Day Air'])
            NextDayAir.create_from_alaska(dest_zip_range, row['Next Day Air'])
            NextDayAirAM.create_from_alaska(dest_zip_range, row['Next Day Air'])
          end
        end

        def alaska_ground_alaska
          csv = FasterCSV.new(open_and_strip("http://www.ups.com/media/en/akz_akg.csv"),
                              :headers => ['Location', 'ZIP Code', 'Area'],
                              :skip_blanks => true)

          zip_to_area = {}
          csv.each do |row|
            if row['ZIP Code'] =~ /^(\d{5})-?(\d+)$/
              zip_to_area[ups_zone_range($1, $2)] = row['Area']
            end
          end

          zip_to_area.each do |source_range, source_area|
            zip_to_area.each do |dest_range, dest_area|
              zone = [source_area, dest_area].sort == ['B', 'C'] ? 3 : 2
              Ground.create_from_row(source_range.begin, source_range.end,
                                     dest_range.begin, dest_range.end,
                                     zone)
            end
          end
        end

        def alaska_ground_continental
          from_csv("http://www.ups.com/media/en/akz_48g.csv",
              ['ZIP Codes', 'Zones']) do |dest_zip_range, row|
            Ground.create_from_alaska(dest_zip_range, row['Zones'])
          end
        end

        # http://www.ups.com/content/us/en/shipping/cost/zones/hawaii.html
        def hawaii_to_continental
          from_csv("http://www.ups.com/media/en/hiz_48pr.csv",
              ['ZIP Codes', 'Next Day Air', 'Next Day Air Saver', 'Air A.M.',
               '2nd Day Air', 'Ground']) do |dest_zip_range, row|

            Ground.create_from_hawaii(dest_zip_range, row['Ground'])
            TwoDayAir.create_from_hawaii(dest_zip_range, row['2nd Day Air'])
            TwoDayAirAM.create_from_hawaii(dest_zip_range, row['Air A.M.'])
            NextDayAirSaver.create_from_hawaii(dest_zip_range, row['Next Day Air Saver'])
            NextDayAir.create_from_hawaii(dest_zip_range, row['Next Day Air'])
            NextDayAirAM.create_from_hawaii(dest_zip_range, row['Next Day Air'])
          end
        end

        def hawaii_intra_ground
          from_csv("http://www.ups.com/media/en/hiz_hi.csv",
              ['ZIP Codes', 'Ground']) do |dest_zip_range, row|
            Ground.create_from_hawaii(dest_zip_range, row['Ground'])
          end
        end

        def hawaii_to_alaska
          from_csv("http://www.ups.com/media/en/hiz_ak.csv",
              ['ZIP Codes', 'Next Day Air', '2nd Day Air',
               'Ground']) do |dest_zip_range, row|

            Ground.create_from_hawaii(dest_zip_range, row['Ground'])
            TwoDayAir.create_from_hawaii(dest_zip_range, row['2nd Day Air'])
            NextDayAir.create_from_hawaii(dest_zip_range, row['Next Day Air'])
            NextDayAirAM.create_from_hawaii(dest_zip_range, row['Next Day Air'])
          end
        end

        def ups_zone_range(gte, lte)
          dest_zip_gte = zip_lowerbound(gte)

          if !lte.blank?
            if lte.length == 2
              dest_zip_lte = zip_upperbound(gte[0..2] + lte)
            elsif lte.length == 1
              dest_zip_lte = zip_upperbound(gte[0..3] + lte)
            else
              dest_zip_lte = zip_upperbound(lte)
            end
          else
            dest_zip_lte = zip_upperbound(gte)
          end

          return (dest_zip_gte.to_i..dest_zip_lte.to_i)
        end
      end
    end

    class HI_AK_Zips
      attr_reader :ground, :next_day_air, :second_day_air
      attr_accessor :zips
      def initialize(ground, nda, sda)
        @ground         = ground
        @next_day_air   = nda
        @second_day_air = sda
        @zips           = []
      end

      def each_range(&block)
        zips_as_ranges.each do |range|
          yield range
        end
      end

      def zips_as_ranges
        ranges = [[]]
        zips.each do |zip|
          if ranges.last.empty? || ranges.last.last + 1 == zip
            ranges.last << zip
          else
            ranges << [zip]
          end
        end
        ranges.map do |range|
          if range.length > 2
            range - range[1..-2]
          elsif range.length == 1
            [range.first, range.first]
          else
            range
          end
        end
      end
    end
  end
end
