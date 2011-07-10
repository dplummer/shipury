module Shipury
  module Fedex
    class Zone < Shipury::Zone
      class Express < self; end
      class Ground < self; end

      class << self
        def download_tables(output_io = StringIO.new, start_zip = 5, finish_zip = 999)
          require 'tempfile'
          require 'net/ftp'
          require 'zip/zip'
          require 'zip/zipfilesystem'

          tempfile = download_all_zones_zip

          Zip::ZipFile.open(tempfile) do |zipfile|
            zipfile.dir.foreach('.') do |filename|
              file = zipfile.file.read(filename).split("\n")
              file.map!(&:rstrip)
              continental_us = file.select { |line| !(line =~ /^"(\d+)-?(\d*)","(\d+|NA)",$/).nil? }
              outer_us = file.select { |line| !(line =~ /^"(\d+)-?(\d*)","(\d+|NA)","(\d+|NA)",$/).nil? }

              source_lower, source_upper = source_range(filename)

              delete_all_for_source(source_lower, source_upper)

              ::FasterCSV.new(continental_us.join("\n")).each do |row|
                unless row[0].blank? || row[1] == 'NA'
                  Express.create_from_row(source_lower, source_upper, row[0], row[1])
                  Ground.create_from_row(source_lower, source_upper, row[0], row[1])
                end
                output_io.print "."
                output_io.flush
              end

              ::FasterCSV.new(outer_us.join("\n")).each do |row|
                unless row[0].blank?
                  unless row[1] == 'NA'
                    Express.create_from_row(source_lower, source_upper, row[0], row[1])
                  end

                  unless row[2] == 'NA'
                    Ground.create_from_row(source_lower, source_upper, row[0], row[2])
                  end
                end
                output_io.print "."
                output_io.flush
              end

              output_io.puts "\nDone with zone file %s\n" % filename
            end
          end
        end

        protected
        def create_from_row(source_lower, source_upper, dest_str, zone)
          dest_gte, dest_lte = destination_range(dest_str)

          begin
          create!(:source_zip_gte      => source_lower,
                  :source_zip_lte      => source_upper,
                  :destination_zip_gte => dest_gte,
                  :destination_zip_lte => dest_lte,
                  :zone                => zone)
          rescue => e
            #TODO Need to ignore duplicates, this should be restricted to only mysql
            #errors
          end
        end

        private
        def source_range(filename)
          source_gte, source_lte = File.basename(filename, '.csv').split('-')
          source_lte ||= source_gte
          return zip_lowerbound(source_gte), zip_upperbound(source_lte)
        end

        def destination_range(dest_str)
          dest_gte, dest_lte = dest_str.split('-')
          dest_lte ||= dest_gte
          return zip_lowerbound(dest_gte), zip_upperbound(dest_lte)
        end

        def download_all_zones_zip
          tempfile = "#{Dir::tmpdir}/AllZones.csv.zip"
          ftp = Net::FTP.new('ftp.fedex.com')
          ftp.login
          ftp.chdir('pub/us/rates/downloads/documents2')
          ftp.getbinaryfile('AllZones.csv.zip', tempfile)
          ftp.close
          tempfile
        end
      end
    end
  end
end
