require "http/client"
require "uri"

module JsonClient
  class InvalidResponse < Exception; end

  macro request_and_decode(method, base_url, path, type)
    result = JsonClient.http_client({{ base_url }}) do |client|
      client.{{ method.id }}({{ path }})
    end

    unless JsonClient.valid_response?(result)
      raise JsonClient::InvalidResponse.new(result.body)
    end

    {{ type }}.from_json(result.body)
  end

  macro get(base_url, path, type)
    JsonClient.request_and_decode(:get, {{ base_url }}, {{ path }}, {{ type }})
  end

  def self.valid_response?(result)
    result.status_code == 200 && result.headers["Content-Type"] == "application/json"
  end

  def self.http_client(url : String, tls = false, &block)
    uri = URI.parse(url)

    client = HTTP::Client.new(host: uri.host.to_s, port: uri.port, tls: tls).tap do |c|
      c.connect_timeout = 120
      c.read_timeout    = 120
      c.dns_timeout     = 30

      c.before_request do |request|
        request.headers["Content-Type"] = "application/json"
        request.headers["User-Agent"] = "deployinator"
        request.headers["Accept"] = "application/json"
      end
    end

    result = yield client
    client.close
    result
  end
end
