class ScryfallDataSyncJob < ApplicationJob
  queue_as :default

  def perform(force_update: false)
    Monitoring::Reporter.log(
      :info,
      "Starting Scryfall data sync job",
      job: self.class.name,
      force_update: force_update
    )


    begin
      sync_service = ScryfallSyncService.new

      if sync_service.update_needed? || force_update
        # Perform the sync
        sync_service.sync_data
        Monitoring::Reporter.log(:info, "Scryfall sync completed successfully", job: self.class.name)

      else
        Monitoring::Reporter.log(:info, "Scryfall sync skipped; no update needed", job: self.class.name)

      end

      # Optionally notify about completion
      # NotificationService.notify_sync_complete(result) if defined?(NotificationService)

    rescue => e
      Monitoring::Reporter.capture_exception(
        e,
        message: "Scryfall sync failed",
        tags: { job: "scryfall.data_sync" },
        extra: { force_update: force_update }
      )

      # Optionally notify about failure
      # NotificationService.notify_sync_failed(e) if defined?(NotificationService)

      raise
    end
  end
end
