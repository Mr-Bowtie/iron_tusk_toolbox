class Admin::ScryfallController < ApplicationController
  def show
    @sync_status = SyncStatus.find_by(sync_type: "scryfall_cards")
    @card_count = CardMetadatum.count
    @recent_cards = CardMetadatum.order(updated_at: :desc).limit(5)
    @update_needed = sync_service.update_needed?
  end

  def sync
    if sync_service.update_needed?
      ScryfallDataSyncJob.perform_later
      flash[:success] = "Scryfall sync job has been queued. Check the Jobs dashboard for progress."
    else
      flash[:info] = "Scryfall data is already up to date."
    end

    redirect_to admin_scryfall_path
  end

  def force_sync
    ScryfallDataSyncJob.perform_later(force_update: true)
    flash[:success] = "Forced Scryfall sync job has been queued. Check the Jobs dashboard for progress."
    redirect_to admin_scryfall_path
  end

  def status
    @sync_status = SyncStatus.find_by(sync_type: "scryfall_cards")

    respond_to do |format|
      format.json do
        if @sync_status
          render json: {
            last_synced_at: @sync_status.last_synced_at,
            sync_details: @sync_status.sync_details_hash,
            card_count: CardMetadatum.count,
            update_needed: sync_service.update_needed?
          }
        else
          render json: {
            last_synced_at: nil,
            sync_details: {},
            card_count: CardMetadatum.count,
            update_needed: true
          }
        end
      end
    end
  end

  private

  def sync_service
    @sync_service ||= ScryfallSyncService.new
  end
end
