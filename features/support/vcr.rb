require 'vcr'

VCR.config do |c|
  c.stub_with :webmock
  c.cassette_library_dir = 'features/cassettes'
  c.default_cassette_options = {
    :record => :new_episodes,
    :match_requests_on => [:host]
  }
end

VCR.cucumber_tags do |t|
  t.tag 'origin_hawaii'
  t.tag 'origin_canada'
  t.tag 'destination_canada'
end
