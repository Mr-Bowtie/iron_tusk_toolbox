# == Schema Information
#
# Table name: collection_decklist_reports
#
#  id                      :bigint           not null, primary key
#  generated_at            :datetime         not null
#  name                    :string           not null
#  selected_decklist_count :integer          default(0), not null
#  shared_card_count       :integer          default(0), not null
#  snapshot                :jsonb            not null
#  unique_card_count       :integer          default(0), not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#
# Indexes
#
#  index_collection_decklist_reports_on_generated_at  (generated_at)
#
class Collection::DecklistReport < ApplicationRecord
  self.table_name = "collection_decklist_reports"

  has_many :decklist_report_decklists,
           class_name: "Collection::DecklistReportDecklist",
           dependent: :destroy
  has_many :decklists, through: :decklist_report_decklists

  validates :name, presence: true
  validates :snapshot, presence: true

  scope :recent_first, -> { order(generated_at: :desc) }
end
