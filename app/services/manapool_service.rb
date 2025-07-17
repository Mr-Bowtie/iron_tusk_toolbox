class ManapoolService < ApplicationService
  def create_manapool_request(url:, method: "get", params: nil)
    uri = URI(url)
    uri.query = URI.encode_www_form(params) unless params.nil? || params.empty?
    req = nil
    case method
    when "get"
      req = Net::HTTP::Get.new(uri)
    when "post"
      req = Net::HTTP::Post.new(uri)
    else
      abort "Please use get or post"
    end

    req["X-ManaPool-Email"] = ENV["MANAPOOL_EMAIL"]
    req["X-ManaPool-Access-Token"] = ENV["MANAPOOL_AUTH_TOKEN"]
    req["Accept"] = "application/json"
    [ req, uri ]
  end

  def fetch_unfulfilled_orders
    req, uri = create_manapool_request(url: "#{API_BASE}/orders", method: "get", params: { is_unfulfilled: true })

    res = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
      http.request(req)
    end

    abort "Failed to fetch orders (#{res.code}): #{res.body}" unless res.is_a?(Net::HTTPSuccess)

    JSON.parse(res.body)
  end

  def extract_cards(orders)
    cards_details = []

    orders.each do |order|
      order_details = fetch_order_details(order["id"])

      order_details["order"]["items"].each do |item|
        piece = item["product"]

        card_data = piece["single"]
        cards_details << {
          scryfall_id: card_data["scryfall_id"],
          card_name: card_data["name"],
          set: card_data["set"],
          condition: card_data["condition_id"],
          foil: card_data["finish_id"],
          number: card_data["number"],
          quantity: item["quantity"]
        }
      end
    end
    combine_duplicate_cards(cards_details)
  end

  private

  def fetch_order_details(order_id)
    req, uri = create_manapool_request(url: "#{API_BASE}/orders/#{order_id}")

    res = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
      http.request(req)
    end

    abort "Failed to fetch order info (#{res.code}): #{res.body}" unless res.is_a?(Net::HTTPSuccess)

    JSON.parse(res.body)
  end

  def combine_duplicate_cards(cards)
    combined = {}

    cards.each do |card|
      # Build a unique key for this card (based on identifying attributes)
      key = [
        card[:scryfall_id],
        card[:condition],
        card[:foil],
        card[:number]
      ]

      if combined.key?(key)
        # Add quantities if this card already exists
        combined[key][:quantity] += card[:quantity]
      else
        # Duplicate the hash so we don't mutate the original
        combined[key] = card.dup
      end
    end

    # Return an array of deduplicated, quantity-summed cards
    combined.values
  end
end
