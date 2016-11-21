require "http/client"
require "uri"

module Deployinator
  class JsonClient(T)
    class InvalidResponse < Exception; end
    class TimeOut < Exception; end

    def initialize(@type : T); end

    def get(base_url, path)
      result = self.class.http_client(base_url) do |client|
        client.get(path)
      end

      unless self.class.valid_response?(result)
        raise InvalidResponse.new(result.body)
      end

      begin
        @type.from_json(result.body)
      rescue e : JSON::ParseException
        raise InvalidResponse.new("Error: #{e.message} Got: '#{result.body}'\n#{caller.join("\n")}")
      end
    end

    # CLASS methods
    def self.post(base_url, path, obj)
      result = JsonClient.http_client(base_url) do |client|
        client.post(path, body: obj.to_json)
      end

      unless JsonClient.valid_response?(result)
        raise InvalidResponse.new(result.body)
      end

      result.status_code
    end

    def self.valid_response?(result)
      result.status_code == 200 && result.headers["Content-Type"] == "application/json"
    end

    def self.http_client(url : String, tls = false, &block)
      uri = URI.parse(url)

      client = HTTP::Client.new(host: uri.host.to_s, port: uri.port, tls: tls).tap do |c|
        c.connect_timeout = 10
        c.read_timeout    = 30
        c.dns_timeout     = 10

        c.before_request do |request|
          request.headers["Content-Type"] = "application/json"
          request.headers["User-Agent"] = "deployinator"
          request.headers["Accept"] = "application/json"
        end
      end

      result = yield client
      client.close
      result
    rescue e : IO::Timeout
      raise TimeOut.new(e.message)
    end
  end
end
