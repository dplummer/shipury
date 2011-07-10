Given "I allow net connect" do
  WebMock.allow_net_connect!
end

Given "I am accepting requests to UPS for a Hawaii origin" do
  WebMock.reset!
  VCR.use_cassette('hawaii_origin') do

  end
  WebMock.stub_request(:post, "https://www.ups.com/ups.app/xml/Rate").
    to_return(File.new('features/support/ups_hawaii_rates.txt'))
end

Given "I am accepting requests for destination Canada" do
  WebMock.reset!
  WebMock.stub_request(:post, "https://www.ups.com/ups.app/xml/Rate").
    to_return(File.new('features/support/ups_destination_canada.txt'))
  WebMock.stub_request(:post, "https://gateway.fedex.com/xml").
    to_return(File.new('features/support/fedex_destination_canada.txt'))
  #WebMock.stub_request(:post, "http://production.shippingapis.com/ShippingAPI.dll").
  #  to_return(File.new('features/support/usps_destination_cananda.txt'))
end

Given "USPS shipping rates are loaded" do
  unless $usps_rates_loaded == true
    base_dir = 'spec/shipping_fixtures'

    stub_request(:get, Shipury::USPS::Carrier::PRICING_URL).
      to_return(File.new("#{base_dir}/usps_pricing_files.html"))

    stub_request(:get, /http:\/\/(pe|www)\.usps\.com\/prices\/_?csv\/(.*)\.csv/).
        to_return do |request|
      File.new(File.join(base_dir, request.uri.to_s.split('/').last))
    end

    Shipury::USPS::Carrier.download_pricing
    $usps_rates_loaded = true
  end
end

Given "Fedex shipping rates are loaded" do
  unless $fedex_rates_loaded == true
    Shipury::Fedex::Carrier.download_pricing
    $fedex_rates_loaded = true
  end
end

Given "UPS shipping rates are loaded" do
  unless $ups_rates_loaded == true
    base_dir = 'spec/shipping_fixtures'

    stub_request(:get, Shipury::UPS::Carrier::RATES_XLS).
      to_return(File.new("#{base_dir}/standard_list_rates.xls"))

    Shipury::UPS::Carrier.download_pricing
    $ups_rates_loaded = true
  end
end

Given "an existing Shipping StoreService" do
  Shipury::Carrier.delete_all
  Shipury::Service.delete_all
  Shipury::Rate.delete_all
  Factory.create(:store_service)
end

Given /^I am shopping for a quote for the following shipping options:$/ do |table|
  @shipping_options = table.rows_hash.with_indifferent_access
end

When /^I shop for a rate from carrier "([^"]*)" service "([^"]*)"$/ do |carrier_name, service_name|
  @carriers ||= {}
  @carriers[carrier_name] ||= Shipury::Carrier.find_by_name(carrier_name)
  @carriers[carrier_name].should be

  service = @carriers[carrier_name].services.find_by_name(service_name)
  service.should be
  @quoted_response = service.quote(@shipping_options)
end

Then /^the quoted price should be "([^"]*)"$/ do |quoted_price|
  if quoted_price.blank?
    @quoted_response.should be_nil
  else
    @quoted_response.should == quoted_price.to_f
  end
end

Then /^I have (\d+) of "([^"]*)"$/ do |count, model|
  model.constantize.count.should == count.to_i
end
