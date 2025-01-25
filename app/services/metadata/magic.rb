require "net/http"
require "pry"

class Metadata::Magic < ApplicationService
  SCRYFALL_BULK_DATA_URL = "https://api.scryfall.com/bulk-data/default-cards"

  def self.get_bulk_data
    # grab bulk data
    response = Net::HTTP.get(URI(SCRYFALL_BULK_DATA_URL))
    parsed_response = JSON.parse(response)
    binding.pry

    # Parse bulk data
    bulk_data = Net::HTTP.get(URI(parsed_response["download_uri"]))
    FastJsonparser.parse(bulk_data)
  end

  def self.process_bulk_data(json_data)
    card_metadata = json_data.map do |md|
      {
        booster: md[:booster],
        cmc: md[:cmc],
        collector_number: md[:collector_number],
        color_identity: md[:color_identity],
        colors: md[:colors],
        frame_effects: md[:frame_effects],
        image_uris: md[:image_uris],
        keywords: md[:keywords],
        layout: md[:layout],
        legalities: md[:legalities],
        mana_cost: md[:mana_cost],
        name: md[:name],
        oracle_text: md[:oracle_text],
        power: md[:power],
        prices: md[:prices],
        produced_mana: md[:produced_mana],
        rarity: md[:rarity],
        set: md[:set],
        set_name: md[:set_name],
        toughness: md[:toughness],
        type_line: md[:type_line],
        tcgplayer_id: md[:tcgplayer_id],
        scryfall_id: md[:id]
      }
    end

    card_metadata
  end

  def self.update_system_data
    execution_time = Benchmark.realtime do
      bulk_data = get_bulk_data
      puts "================ Data Received & Parsed ================"
      processed_data = process_bulk_data(bulk_data)
      puts "================== Data Transformed ===================="
      CardMetadatum.upsert_all(processed_data, unique_by: :scryfall_id)
    end

    puts "Metadata update took: #{execution_time}"
  end
end
