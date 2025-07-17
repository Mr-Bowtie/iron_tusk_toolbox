# Legacy service - kept for compatibility but deprecated
# Use ScryfallSyncService instead for new implementations
require "net/http"

class Metadata::Magic < ApplicationService
  SCRYFALL_BULK_DATA_URL = "https://api.scryfall.com/bulk-data/default-cards"

  # @deprecated Use ScryfallSyncService.new.sync_data instead
  def self.update_system_data
    Rails.logger.warn "Metadata::Magic.update_system_data is deprecated. Use ScryfallSyncService instead."
    
    sync_service = ScryfallSyncService.new
    result = sync_service.sync_data
    
    puts "Metadata update took: #{result[:stats][:execution_time]}"
    result
  end

  # Legacy methods kept for backward compatibility
  def self.get_bulk_data
    sync_service = ScryfallSyncService.new
    sync_service.send(:fetch_bulk_metadata)
  end

  def self.process_bulk_data(json_data)
    sync_service = ScryfallSyncService.new
    sync_service.send(:process_card_batch, json_data)
  end
end
