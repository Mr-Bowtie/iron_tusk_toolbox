require "net/http"
require "pry"

class Metadata < ApplicationService
  SCRYFALL_BULK_DATA_URL = "https://api.scryfall.com/bulk-data/oracle-cards"

  def self.get_bulk_data
    # grab bulk data
    response = Net::HTTP.get(URI(SCRYFALL_BULK_DATA_URL))
    puts response
    parsed_response = JSON.parse(response)
    puts parsed_response
    puts "===================================="

    # Parse bulk data
    bulk_data = Net::HTTP.get(URI(parsed_response["download_uri"]))
    binding.pry
    # JSON.parse(bulk_data)
  end

  def self.process_bulk_data(json_data)
    # transform into CardMetadatum objects
    card_metadata = json_data.map do |md|
      {}
    end

    card_metadata
  end

  def self.update_system_data
    bulk_data = get_bulk_data
    processed_data = process_bulk_data(bulk_data)
    CardMetadatum.upsert_all(processed_data, unique_by: :scryfall_id)
  end
end
