require "helper"
require "fluent/plugin/filter_imds.rb"
require 'webmock/test_unit'
WebMock.disable_net_connect!

class ImdsFilterTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup
    @time = Fluent::Engine.now
  end

  CONFIG = %[
    containerIdInput "\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000a0a000a0-0000-0a00-aaa0-aaaa00aa0a00\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000NextKVPKey\u0000\u0000\u0000\u0000\u0000NextKVPValue\u0000\u0000\u0000\u0000\u0000"
  ]
  IMDS = <<-TEXT
    {\"compute\":{\"azEnvironment\":\"AzurePublicCloud\",\"customData\":\"\",\"location\":\"eastus\",
    \"name\":\"fluentd-test2\",\"offer\":\"UbuntuServer\",\"osType\":\"Linux\",\"placementGroupId\":\"\",
    \"plan\":{\"name\":\"\",\"product\":\"\",\"publisher\":\"\"},\"platformFaultDomain\":\"0\",\"platformUpdateDomain\":\"0\",
    \"provider\":\"Microsoft.Compute\",\"publicKeys\":[],\"publisher\":\"Canonical\",
    \"resourceGroupName\":\"juelm-imds-fluentd\",
    \"resourceId\":\"/subscriptions/0000a0a0-0a0a-000a-0000-000a000aa0a/resourceGroups/juelm-imds-fluentd/providers/Microsoft.Compute/virtualMachines/fluentd-test2\",
    \"sku\":\"18.04-LTS\",\"storageProfile\":{\"dataDisks\":[],\"imageReference\":{\"id\":\"\",\"offer\":\"UbuntuServer\",
    \"publisher\":\"Canonical\",\"sku\":\"18.04-LTS\",\"version\":\"latest\"},\"osDisk\":{\"caching\":\"ReadWrite\",
    \"createOption\":\"FromImage\",\"diffDiskSettings\":{\"option\":\"\"},\"diskSizeGB\":\"30\",
    \"encryptionSettings\":{\"enabled\":\"false\"},\"image\":{\"uri\":\"\"},
    \"managedDisk\":{\"id\":\"/subscriptions/0000a0a0-0a0a-000a-0000-000a000aa0a/resourceGroups/JUELM-IMDS-FLUENTD/providers/Microsoft.Compute/disks/fluentd-test2_disk1_b2a49f76712c41aa850453e182f6c4e1\",
    \"storageAccountType\":\"Premium_LRS\"},\"name\":\"fluentd-test2_disk1_b2a49f76712c41aa850453e182f6c4e1\",
    \"osType\":\"Linux\",\"vhd\":{\"uri\":\"\"},\"writeAcceleratorEnabled\":\"false\"}},
    \"subscriptionId\":\"0000a0a0-0a0a-000a-0000-000a000aa0a\",\"tags\":\"\",\"tagsList\":[],
    \"version\":\"18.04.202003170\",\"vmId\":\"a7ff7831-57cf-4fa6-9016-726d1c81dfdf\",\"vmScaleSetName\":\"\",
    \"vmSize\":\"Standard_B2s\",\"zone\":\"\"},
    \"network\":{\"interface\":[{\"ipv4\":{\"ipAddress\":[{\"privateIpAddress\":\"172.16.0.5\",
    \"publicIpAddress\":\"52.179.11.145\"}],\"subnet\":[{\"address\":\"172.16.0.0\",\"prefix\":\"24\"}]},
    \"ipv6\":{\"ipAddress\":[]},\"macAddress\":\"000D3A12811D\"}]}}
  TEXT

  def create_driver(conf = CONFIG)
    Fluent::Test::Driver::Filter.new(Fluent::Plugin::ImdsFilter).configure(conf)
  end

  test "test-to-see-that-filter-returns-correct-message-and-imds-data" do
    stub_request(:get, "http://169.254.169.254/metadata/instance?api-version=2019-11-01").
    with(
      headers: {
  	  'Accept'=>'*/*',
  	  'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
  	  'Host'=>'169.254.169.254',
  	  'Metadata'=>'true',
  	  'User-Agent'=>'Ruby'
      }).
    to_return(status: 200, body: IMDS, headers: {})
    d = create_driver()
    d.run do
      d.feed("test1", @time, {"Matt says" => "Hello"})
    end
    assert_equal(d.filtered_records[0]["Matt says"], "Hello")
    assert_equal(d.filtered_records[0]["subscriptionId"], "0000a0a0-0a0a-000a-0000-000a000aa0a")
    assert_equal(d.filtered_records[0]["region"], "eastus")
    assert_equal(d.filtered_records[0]["resourceGroup"], "juelm-imds-fluentd")
    assert_equal(d.filtered_records[0]["vmName"], "fluentd-test2")
    assert_equal(d.filtered_records[0]["vmSize"], "Standard_B2s")
    assert_equal(d.filtered_records[0]["vmId"], "a7ff7831-57cf-4fa6-9016-726d1c81dfdf")
    assert_equal(d.filtered_records[0]["placementGroup"], "") 
    assert_equal(d.filtered_records[0]["containerID"], "a0a000a0-0000-0a00-aaa0-aaaa00aa0a00")
  end

  test "test-to-see-that-filter-returns-records-in-correct-format" do
    stub_request(:get, "http://169.254.169.254/metadata/instance?api-version=2019-11-01").
    with(
      headers: {
  	  'Accept'=>'*/*',
  	  'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
  	  'Host'=>'169.254.169.254',
  	  'Metadata'=>'true',
  	  'User-Agent'=>'Ruby'
      }).
    to_return(status: 200, body: IMDS, headers: {})
    d = create_driver()
    d.run do
      d.feed("test1", @time, {"Matt says" => "Hello"})
    end
    assert_equal(d.filtered_records[0]["Matt says"], "Hello")
    assert_equal(d.filtered_records[0]["subscriptionId"], "0000a0a0-0a0a-000a-0000-000a000aa0a")
    assert_equal(d.filtered_records[0]["region"], "eastus")
    assert_equal(d.filtered_records[0]["resourceGroup"], "juelm-imds-fluentd")
    assert_equal(d.filtered_records[0]["vmName"], "fluentd-test2")
    assert_equal(d.filtered_records[0]["vmSize"], "Standard_B2s")
    assert_equal(d.filtered_records[0]["vmId"], "a7ff7831-57cf-4fa6-9016-726d1c81dfdf")
    assert_equal(d.filtered_records[0]["placementGroup"], "") 
    assert_equal(d.filtered_records[0]["containerID"], "a0a000a0-0000-0a00-aaa0-aaaa00aa0a00")

    stub_request(:get, "http://169.254.169.254/metadata/instance?api-version=2019-11-01").
    with(
      headers: {
  	  'Accept'=>'*/*',
  	  'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
  	  'Host'=>'169.254.169.254',
  	  'Metadata'=>'true',
  	  'User-Agent'=>'Ruby'
      }).
    to_return(status: 404, body: IMDS, headers: {})

    d.run do
      d.feed("test1", @time, {"Matt says" => "Hello Again"})
    end
    assert_equal(d.filtered_records[1]["Matt says"], "Hello Again")
    assert_equal(d.filtered_records[1]["subscriptionId"], "0000a0a0-0a0a-000a-0000-000a000aa0a")
    assert_equal(d.filtered_records[1]["region"], "eastus")
    assert_equal(d.filtered_records[1]["resourceGroup"], "juelm-imds-fluentd")
    assert_equal(d.filtered_records[1]["vmName"], "fluentd-test2")
    assert_equal(d.filtered_records[1]["vmSize"], "Standard_B2s")
    assert_equal(d.filtered_records[1]["vmId"], "a7ff7831-57cf-4fa6-9016-726d1c81dfdf")
    assert_equal(d.filtered_records[1]["placementGroup"], "") 
    assert_equal(d.filtered_records[1]["containerID"], "a0a000a0-0000-0a00-aaa0-aaaa00aa0a00")
  end

  test "test-to-see-that-filter-returns-error-message-on-http-failure" do
    error = 404
    message = Net::HTTPResponse::CODE_TO_OBJ['404']
    stub_request(:get, "http://169.254.169.254/metadata/instance?api-version=2019-11-01").
    with(
      headers: {
  	  'Accept'=>'*/*',
  	  'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
  	  'Host'=>'169.254.169.254',
  	  'Metadata'=>'true',
  	  'User-Agent'=>'Ruby'
      }).
    to_return(status: 404, body: IMDS, headers: {})
    d = create_driver()
    d.run do
      d.feed("test1", @time, {"Matt says" => "Hello"})
    end
    assert_equal(d.filtered_records[0]["Matt says"], "Hello")
    assert_equal(d.filtered_records[0]["subscriptionId"], "")
    assert_equal(d.filtered_records[0]["region"], "")
    assert_equal(d.filtered_records[0]["resourceGroup"], "")
    assert_equal(d.filtered_records[0]["vmName"], "")
    assert_equal(d.filtered_records[0]["vmSize"], "")
    assert_equal(d.filtered_records[0]["vmId"], "")
    assert_equal(d.filtered_records[0]["placementGroup"], "")
    
    unstrippedDistro = `lsb_release -si`
    assert_equal(d.filtered_records[0]["distro"], unstrippedDistro.strip)
    unstrippedVersion = `lsb_release -sr`
    assert_equal(d.filtered_records[0]["distroVersion"], unstrippedVersion.strip)
    unstrippedKernel = `uname -r`
    assert_equal(d.filtered_records[0]["kernelVersion"], unstrippedKernel.strip)

    assert_equal(d.filtered_records[0]["containerID"], "a0a000a0-0000-0a00-aaa0-aaaa00aa0a00")
  end
end
