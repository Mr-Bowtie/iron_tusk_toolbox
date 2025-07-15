require "net/http"
require "open-uri"
require "benchmark"
require "json/streamer"
require "yajl/ffi"

class ScryfallSyncService < ApplicationService
  @@sync_in_progress = false

  def self.sync_in_progress
    @@sync_in_progress
  end

  def self.sync_in_progress=(value)
    @@sync_in_progress = value
  end

  SCRYFALL_BULK_DATA_URL = "https://api.scryfall.com/bulk-data/default-cards"
  BATCH_SIZE = 1000

  attr_reader :sync_stats

  def initialize
    @sync_stats = {
      total_batches: 0,
      execution_time: 0
    }
  end

  def sync_data
    return { success: false, error: "Sync already in progress" } if @@sync_in_progress

    @sync_stats[:execution_time] = Benchmark.realtime do
      @@sync_in_progress = true
      perform_sync
    end

    Rails.logger.info "Scryfall sync finished in #{@sync_stats[:execution_time].round(2)}s,
                      enqueued #{@sync_stats[:total_batches]} batch jobs"
  end

  def update_needed?
    # Check if we have any data
    return true if CardMetadatum.count == 0

    # Check last update time (update daily)
    last_update = SyncStatus.find_by(sync_type: "scryfall_cards")&.last_synced_at
    return true if last_update.nil?

    # Update if more than 23 hours have passed (allowing for some flexibility)
    last_update < 23.hours.ago
  end

  private

  def perform_sync
    Rails.logger.info "Fetching Scryfall bulk data metadata..."
    bulk_metadata = fetch_bulk_metadata

    Rails.logger.info "Downloading bulk data file..."
    download_and_buffer(bulk_metadata["download_uri"])

    update_sync_status
  end

  def fetch_bulk_metadata
    response = Net::HTTP.get(URI(SCRYFALL_BULK_DATA_URL))
    parsed_response = JSON.parse(response)

    unless parsed_response["object"] == "bulk_data"
      raise "Invalid response from Scryfall API"
    end

    parsed_response
  end

  def download_and_buffer(download_uri)
    buffer = []
    uri = URI(download_uri)

    URI.open(uri) do |io|
      streamer = Json::Streamer.parser(event_generator: Yajl::FFI::Parser.new, file_io: io, chunk_size: 1024)
      streamer.get(nesting_level: 1) do |object|
        buffer << map_card_attrs(object)
        if buffer.size >= BATCH_SIZE
          enqueue_batch(buffer)
          buffer.clear
        end
      end
      enqueue_batch(buffer) if buffer.any?
    end
  end

  def map_card_attrs(card_data)
    front_image_uris = {}
    back_image_uris = {}

    unless card_data[:card_faces].nil?
      front_image_uris = card_data[:card_faces][0][:image_uris]
      back_image_uris = card_data[:card_faces][1][:image_uris]
    end

    {
      scryfall_id: card_data["id"],
      tcgplayer_id: card_data["tcgplayer_id"],
      name: card_data["name"],
      mana_cost: card_data["mana_cost"],
      cmc: card_data["cmc"],
      type_line: card_data["type_line"],
      oracle_text: card_data["oracle_text"],
      power: card_data["power"],
      toughness: card_data["toughness"],
      colors: card_data["colors] || ["],
      color_identity: card_data["color_identity] || ["],
      keywords: card_data["keywords] || ["],
      legalities: card_data["legalities"] || {},
      frame_effects: card_data["frame_effects] || ["],
      layout: card_data["layout"],
      produced_mana: card_data["produced_mana] || ["],
      set: card_data["set"],
      set_name: card_data["set_name"],
      collector_number: card_data["collector_number"],
      rarity: card_data["rarity"],
      booster: card_data["booster"],
      front_image_uris: front_image_uris,
      back_image_uris: back_image_uris,
      image_uris: card_data["image_uris"] || {},
      prices: card_data["prices"] || {},
      created_at: Time.current,
      updated_at: Time.current
    }
  end

  def enqueue_batch(records)
    @sync_stats[:total_batches] += 1
    ScryfallBatchUpsertJob.perform_later(card_data: records)
  end

  def update_sync_status
    SyncStatus.upsert(
      { sync_type: "scryfall_cards", last_synced_at: Time.current },
      unique_by: :sync_type
    )
  end
end
