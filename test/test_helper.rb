require 'minitest/spec'
require 'minitest/autorun'

$: << File.expand_path("../../lib", __FILE__)
require 'data_bindings'
require 'fakeweb'

FakeWeb.allow_net_connect = false

Dir[File.expand_path("../fixtures/*", __FILE__)].each do |f|
  FakeWeb.register_uri(:get, "http://localhost/#{File.basename(f)}", :body => File.read(f))
  FakeWeb.register_uri(:get, "http://secret/#{File.basename(f)}", :body => "Unauthorized", :status => ["401", "Unauthorized"])
  FakeWeb.register_uri(:get, "http://test:user@secret/#{File.basename(f)}", :body => File.read(f))
end

require 'bson'
require 'tnetstring'