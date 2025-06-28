class SyncStatus < ApplicationRecord
  validates :sync_type, presence: true, uniqueness: true
  
  scope :scryfall_cards, -> { where(sync_type: 'scryfall_cards') }
  
  def sync_details_hash
    sync_details.present? ? JSON.parse(sync_details) : {}
  end
  
  def last_sync_successful?
    sync_details_hash.fetch('success', false)
  end
  
  def cards_synced
    sync_details_hash.fetch('total_cards', 0)
  end
end