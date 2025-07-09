# == Schema Information
#
# Table name: sync_statuses
#
#  id             :bigint           not null, primary key
#  last_synced_at :datetime
#  sync_details   :text
#  sync_type      :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_sync_statuses_on_sync_type  (sync_type) UNIQUE
#
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
