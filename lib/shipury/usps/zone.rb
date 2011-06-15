module Shipury
  module USPS
    class Zone < Shipury::Zone
      ZONECHART_URL = "http://postcalc.usps.gov/Zonecharts/ZoneChartPrintable.aspx?zipcode="

      class << self
        def download_tables(output_io = StringIO.new, start_zip = 5, finish_zip = 999)
          (start_zip..finish_zip).each do |zip|
            zip_page = page(zip)
            transaction do
              delete_all(["source_zip_gte = ?", zip * 100])
              zip_page.search("table[@id=ctl03_Table1]/tr").each do |tr|
                tds = tr.xpath("td")
                if tds[0].content =~ /\d+-*\d*/
                  create_from_download(zip, tds[0].content, tds[1].content) if tds[0] && tds[1]
                  create_from_download(zip, tds[2].content, tds[3].content) if tds[2] && tds[3]
                  create_from_download(zip, tds[4].content, tds[5].content) if tds[4] && tds[5]
                  create_from_download(zip, tds[6].content, tds[7].content) if tds[6] && tds[7]
                  output_io.print "."
                  output_io.flush
                end
              end
              output_io.puts "\nDone with zone table %03d\n" % zip
            end
          end
        end

        private
        def create_from_download(source, dest_range, zone)
          source_gte = "%03d" % source
          source_lte = "%03d" % source

          dest_gte, dest_lte = dest_range.split('---')
          dest_lte ||= dest_gte

          zone = zone.gsub(/[^\d]/,'')

          create!(:source_zip_gte      => zip_lowerbound(source_gte),
                  :source_zip_lte      => zip_upperbound(source_lte),
                  :destination_zip_gte => zip_lowerbound(dest_gte),
                  :destination_zip_lte => zip_upperbound(dest_lte),
                  :zone                => zone)
        end

        def agent
          @agent ||= Mechanize.new
        end

        def page(zip)
          agent.get(ZONECHART_URL + ("%03d" % zip))
        end
      end
    end
  end
end
