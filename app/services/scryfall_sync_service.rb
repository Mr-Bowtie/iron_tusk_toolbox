require "net/http"
require "benchmark"

class ScryfallSyncService < ApplicationService
  SCRYFALL_BULK_DATA_URL = "https://api.scryfall.com/bulk-data/default-cards"
  BATCH_SIZE = 1000

  attr_reader :sync_stats

  def initialize
    @sync_stats = {
      total_cards: 0,
      new_cards: 0,
      updated_cards: 0,
      errors: 0,
      execution_time: 0
    }
  end

  def sync_data
    @sync_stats[:execution_time] = Benchmark.realtime do
      perform_sync
    end

    Rails.logger.info "Sync completed in #{@sync_stats[:execution_time].round(2)} seconds"
    Rails.logger.info "Stats: #{@sync_stats}"

    { success: true, stats: @sync_stats }
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
    raw_data = download_bulk_data(bulk_metadata["download_uri"])

    Rails.logger.info "Processing and importing data..."
    import_data(raw_data)

    # Update sync status
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

  def download_bulk_data(download_uri)
    uri = URI(download_uri)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if uri.scheme == "https"

    request = Net::HTTP::Get.new(uri)
    response = http.request(request)

    unless response.code == "200"
      raise "Failed to download bulk data: HTTP #{response.code}"
    end

    FastJsonparser.parse(response.body)
  end

  def import_data(json_data)
    work_queue = Queue.new
    threads = []
    @sync_stats[:total_cards] = json_data.size
    Rails.logger.info "Processing #{@sync_stats[:total_cards]} cards..."

    5.times do
      threads << Thread.new do
        while (batch = work_queue.pop) != :END
          processed_batch = process_card_batch(batch)
          import_batch(processed_batch)
        end
      end
    end

    json_data.each_slice(BATCH_SIZE).with_index do |batch, index|
      Rails.logger.info "Processing batch #{index + 1}/#{(@sync_stats[:total_cards] / BATCH_SIZE.to_f).ceil}"
      
      work_queue << batch
    end

    # signal threads to finish 
    5.times {work_queue << :END}
    threads.each(&:join)
  end

  def process_card_batch(batch)
    batch.map do |card_data|
      front_image_uris = {}
      back_image_uris = {}

      unless card_data[:card_faces].nil?
        front_image_uris = card_data[:card_faces][0][:image_uris]
        back_image_uris = card_data[:card_faces][1][:image_uris]
      end

      {
        scryfall_id: card_data[:id],
        tcgplayer_id: card_data[:tcgplayer_id],
        name: card_data[:name],
        mana_cost: card_data[:mana_cost],
        cmc: card_data[:cmc],
        type_line: card_data[:type_line],
        oracle_text: card_data[:oracle_text],
        power: card_data[:power],
        toughness: card_data[:toughness],
        colors: card_data[:colors] || [],
        color_identity: card_data[:color_identity] || [],
        keywords: card_data[:keywords] || [],
        legalities: card_data[:legalities] || {},
        frame_effects: card_data[:frame_effects] || [],
        layout: card_data[:layout],
        produced_mana: card_data[:produced_mana] || [],
        set: card_data[:set],
        set_name: card_data[:set_name],
        collector_number: card_data[:collector_number],
        rarity: card_data[:rarity],
        booster: card_data[:booster],
        front_image_uris: front_image_uris,
        back_image_uris: back_image_uris,
        image_uris: card_data[:image_uris] || {},
        prices: card_data[:prices] || {},
        created_at: Time.current,
        updated_at: Time.current
      }
    rescue => e
      Rails.logger.error "Error processing card #{card_data&.dig('id')}: #{e.message}"
      @sync_stats[:errors] += 1
      nil
    end.compact
  end

  def import_batch(processed_batch)
    return if processed_batch.empty?

    result = CardMetadatum.upsert_all(
      processed_batch.uniq { |card| card[:scryfall_id]},
      unique_by: :scryfall_id,
      returning: [ :id, :scryfall_id, :created_at, :updated_at ]
    )

    # Track new vs updated records
    # result.each do |record|
    #   binding.pry
    #   if record.created_at == record.updated_at
    #     @sync_stats[:new_cards] += 1
    #   else
    #     @sync_stats[:updated_cards] += 1
    #   end
    # end
  end

  def update_sync_status
    SyncStatus.find_or_create_by(sync_type: "scryfall_cards") do |status|
      status.last_synced_at = Time.current
      status.sync_details = @sync_stats.to_json
    end.update!(
      last_synced_at: Time.current,
      sync_details: @sync_stats.to_json
    )
  end
end
