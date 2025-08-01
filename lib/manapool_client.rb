require "net/http"
require "uri"
require "open-uri"

module ManapoolClient
  API_BASE = "https://manapool.com/api/v1/seller"

  def self.create_request(url:, method: "get", params: nil)
    uri = URI(url)
    uri.query = URI.encode_www_form(params) if params&.any?

    req = case method
    when "get" then Net::HTTP::Get.new(uri)
    when "post" then Net::HTTP::Post.new(uri)
    else raise ArgumentError, "Unsupported HTTP method"
    end

    req["X-ManaPool-Email"] = ENV["MANAPOOL_EMAIL"]
    req["X-ManaPool-Access-Token"] = ENV["MANAPOOL_AUTH_TOKEN"]
    req["Accept"] = "application/json"

    [ req, uri ]
  end

  def self.fetch_orders(unfulfilled: true, limit: 100)
    offset = 0
    orders = []

    loop do
      req, uri = create_request(
        url: "#{API_BASE}/orders",
        method: "get",
        params: { is_unfulfilled: unfulfilled, limit: limit, offset: offset }
      )

      res = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
        http.request(req)
      end

      raise "Failed to fetch orders: #{res.code} - #{res.body}" unless res.is_a?(Net::HTTPSuccess)

      chunk = JSON.parse(res.body)["orders"]
      orders.concat(chunk)
      break if chunk.size < limit

      offset += chunk.size
    end

    orders
  end

  def self.fetch_order_details(order_id)
    req, uri = create_request(url: "#{API_BASE}/orders/#{order_id}")

      res = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
        http.request(req)
      end

      abort "Failed to fetch order info (#{res.code}): #{res.body}" unless res.is_a?(Net::HTTPSuccess)

      JSON.parse(res.body)
  end
end
