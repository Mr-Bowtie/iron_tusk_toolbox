class ScryfallDataSyncJob < ApplicationJob
  queue_as :default

  def perform(force_update: false)
    Rails.logger.info "Starting Scryfall data sync job (force_update: #{force_update})"


    begin
      sync_service = ScryfallSyncService.new

      if sync_service.update_needed? || force_update
        # Perform the sync
        sync_service.sync_data
        Rails.logger.info "Scryfall sync completed successfully: !"

      else
        Rails.logger.info "No update needed"

      end

      # Optionally notify about completion
      # NotificationService.notify_sync_complete(result) if defined?(NotificationService)

    rescue => e
      Rails.logger.error "Scryfall sync failed: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      # Optionally notify about failure
      # NotificationService.notify_sync_failed(e) if defined?(NotificationService)

      raise e
    end
  end
end
