require "http/client"
require "uri"

def http_client(url : String, tls = false, &block)
  uri = URI.parse(url)

  client = HTTP::Client.new(host: uri.host.to_s, port: uri.port, tls: tls).tap do |c|
    c.connect_timeout = 120
    c.read_timeout    = 120
    c.dns_timeout     = 30

    c.before_request do |request|
      request.headers["Content-Type"] = "application/json"
      request.headers["User-Agent"] = "deployinator"
    end
  end

  result = yield client
  client.close
  result
end
