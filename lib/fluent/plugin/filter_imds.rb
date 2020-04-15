
require "fluent/plugin/filter"
require 'net/http'
require 'uri'

module Fluent
  module Plugin
    class ImdsFilter < Fluent::Plugin::Filter
      Fluent::Plugin.register_filter("imds", self)

      #The filter obtains ContainerId via HyperV key/value pair data exchange.
      #If tests are run outside of Azure the call to get containerId will throw an error
      #pass a string to containerIdInput to avoid this (e.g. for testing)
      config_param :containerIdInput, :string, :default => ""

      #Method to format value retrieved from HyperV key/value pair data exchange
      def stripKVPValue(unstrippedString)
        reachedStartOfContainerId = false
        containerID = ""
        unstrippedString.each_char {|c|
            if c == "\u0000" 
                if reachedStartOfContainerId
                    return containerID
                end
            else
                if !reachedStartOfContainerId
                    reachedStartOfContainerId = true
                end
                containerID += c
            end
        }
        containerID
      end

      def fetchIMDS()
        uri = URI.parse("http://169.254.169.254/metadata/instance?api-version=2019-11-01")
        request = Net::HTTP::Get.new(uri)
        request["Metadata"] = "true"

        req_options = {
          use_ssl: uri.scheme == "https",
        }

        response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
        end

        if response.is_a?(Net::HTTPSuccess) 
          @IMDS = JSON.parse(response.body)
        end
      end

      def start
        super
        @IMDS = {"compute" => {"subscriptionId" => "",
                               "location" => "",
                               "resourceGroupName" => "",
                               "name" => "",
                               "vmSize" => "",
                               "vmId" => "",
                               "placementGroupId" => ""}}
        fetchIMDS()
      end

      def filter(tag, time, record)

        data = @IMDS

        record["subscriptionId"] = data["compute"]["subscriptionId"]
        record["region"] = data["compute"]["location"]
        record["resourceGroup"] = data["compute"]["resourceGroupName"]
        record["vmName"] = data["compute"]["name"]
        record["vmSize"] = data["compute"]["vmSize"]
        record["vmId"] = data["compute"]["vmId"]
        record["placementGroup"] = data["compute"]["placementGroupId"]
        unstrippedDistro = `lsb_release -si`
        record["distro"] = unstrippedDistro.strip
        unstrippedVersion = `lsb_release -sr`
        record["distroVersion"] = unstrippedVersion.strip
        unstrippedKernel = `uname -r`
        record["kernelVersion"] = unstrippedKernel.strip
        if(@containerIdInput == "")
          unstrippedContainerId = `cat /var/lib/hyperv/.kvp_pool_3 | sed -e 's/^.*VirtualMachineName//'`
        else
          unstrippedContainerId = @containerIdInput
        end
        strippedContainerId = stripKVPValue(unstrippedContainerId)
        record["containerID"] = strippedContainerId

        record
      end
    end
  end
end
