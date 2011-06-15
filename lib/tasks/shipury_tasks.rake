namespace :shipury do
  desc "Download and source prices for all carriers"
  task :rates => ['usps:rates', 'fedex:rates', 'ups:rates']
  
  desc "Download and source zones for all carriers"
  task :zones => ['usps:zones', 'fedex:zones', 'ups:zones']

  namespace :usps do
    desc "Download and source zone tables from usps.com"
    task :zones => :environment do
      Shipury::USPS::Zone.download_tables(STDOUT)
    end

    desc "Download and source prices from usps.com"
    task :rates => :environment do
      Shipury::USPS::Carrier.download_pricing(STDOUT)
    end
  end

  namespace :fedex do
    desc "Download and source zone tables from ftp.fedex.com"
    task :zones => :environment do
      Shipury::Fedex::Zone.download_tables(STDOUT)
    end

    desc "Download and source prices from ftp.fedex.com"
    task :rates => :environment do
      Shipury::Fedex::Carrier.download_pricing(STDOUT)
    end
  end

  namespace :ups do
    desc "Download and source zone tables from ups.com"
    task :zones => :environment do
      Shipury::UPS::Zone.download_tables(STDOUT)
    end

    desc "Download and source prices from ups.com"
    task :rates => :environment do
      Shipury::UPS::Carrier.download_pricing(STDOUT)
    end
  end
end
